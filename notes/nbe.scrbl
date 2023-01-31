#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt"
          (for-label racket rackunit))
@(use-mathjax)
@(mathjax-preamble)

@title[#:style (with-html5 manual-doc-style)]{Normalization by evaluation}
@; by: Lylat, 2023-01-23
@section{Deciding equivalence}

We now shift topics to deciding if two lambda terms are equal, for the intuitive notion
of equality. Some of you are likely screaming "α-equivalence", and this is somewhat correct.
Furthermore, since we decided to use DeBruijn levels, we already even have definitionally
alpha-equivalent terms, and don't have to worry about substitution.

However, consider the following:
@$${
(\lambda x. 2) 3 \stackrel{?}{\equiv} 2
}
Well, this is intuitively true, right? We can perform a β-reduction to make them equivalent.
But these terms aren't alpha-equivalent.

In general, to solve a problem like this, even in the case of
@$${
(\lambda x. y) (\lambda x. x) \stackrel{?}{\equiv} y
}
we need to know a lot about the lambda calculus: we need to know whether or not @${y}
contains @${x} in its free variables, for one, we need to know its behavior when passed
@${\lambda x. x} as an argument...

So can we just compare the results of evaluation? Let's give it a shot.

@section{Data definitions for STLC}
First, we define a few of our important data definitions. We add @tt{let} to our syntax:
@#reader scribble/comment-reader
(racketblock
  ;; A Syntax is one of:
  ;; A DeBruijn *level*:
  ;; - (syntax-local Number)
  ;; A lambda:
  ;; - (syntax-lam Symbol Syntax)
  ;; A let-binding:
  ;; - (syntax-let Symbol Syntax Syntax)
  ;; An application:
  ;; - (syntax-app Syntax Syntax)
  (struct syntax-local (n) #:transparent)
  (struct syntax-lam (var body) #:transparent)
  (struct syntax-let (var exp body) #:transparent)
  (struct syntax-app (rator rand) #:transparent)
)
Since this is just simply-typed lambda calculus with no constants, our return value is going
to be a closure:
@#reader scribble/comment-reader
(racketblock
  ;; A Closure is a (closure Syntax Environment)
  (struct closure (term env) #:transparent)
  
  ;; A Value is a Closure
)
Finally, we need to actually define our environment, which is lazy for surprise reasons that will
help us later:
@#reader scribble/comment-reader
(racketblock
;; A Environment is a [ListOf [PromiseOf Value]]

;; empty-env : -> Environment
(define (empty-env)
  '())

;; extend-env : Environment [PromiseOf Value]] -> Environment
(define (extend-env env x)
  (cons x env))

;; apply-env : Environment Number -> [PromiseOf Value]
(define (evaluate/apply-env env n)
  (list-ref env n))

;; env-size : Environment -> Number
(define (env-size env)
  (length env))
)
as well as provide the usual 311-esque functions for environment usage.

@section{Building terms with DeBruijn levels (or: continuation HOAS)}
We need a bit of scaffolding to actually write out our terms with DeBruijn levels.
The upshot of DeBruijn indices is that we can very easily plug things, something we lose with
levels. However, we no longer have to do shifting math.

We define a @italic{term builder}, which takes an environment size and gives us a corresponding
term with DeBruijn levels. To build terms, we will invoke the term builder to get a @tt{Syntax}.
@#reader scribble/comment-reader
(racketblock
  ;; A [TB X] is an [Number -> X]
  
  ;; run-term-builder : {X} Environment [TB X] -> X
  ;; Produces the built core term, given an environment.
  (define (run-term-builder env k)
    (k (env-size env)))
)

If you're cheeky, you may think of the continuation monad.

Yes.

Moving on, we first define a builder which is our base case for building these terms: given a DeBruijn
index, it shifts it to a level. (Note that we don't have to carry around indices: we'll see this in a bit.)
@#reader scribble/comment-reader
(racketblock
  ;; tb/var : Number -> [TB Syntax]
  ;; Given a DeBruijn index, produce a term builder giving a DeBruijn level in syntax.
  (define (tb/var lvl)
    (λ (size)
      (syntax-local (- size lvl 1))))
  
  (module+ test
    (check-equal? ((tb/var 1) 3) (syntax-local 1))
    (check-equal? ((tb/var 0) 1) (syntax-local 0)))
)

We then provide some more helpers that continue building the continuation, but increment the environment
size (thereby binding a variable):
@#reader scribble/comment-reader
(racketblock
  ;; tb/bind-var : {X} [Number -> [TB X]] -> [TB X]
  ;; Take the given term-builder-builder, and increment its environment size.
  (define (tb/bind-var k)
    (λ (size)
      ((k size) (+ size 1))))
)
and one that scopes out a variable, binding it for a given body (noting that we represent the body as
taking a term-builder and returning a term-builder):
@#reader scribble/comment-reader
(racketblock
  ;; tb/scope : {X} [[TB Syntax] -> [TB X]] -> [TB X]
  ;; Scopes out a variable, binding it for the given term-builder-builder.
  (define (tb/scope k)
    (tb/bind-var (λ (lvl) (k (tb/var lvl)))))
)

Finally, we provide builders for let-bindings, lambdas, and applications. The former two take
functions from term builders to term builders, where the input to the function represents the bound
variable:
@#reader scribble/comment-reader
(racketblock
  ;; tb/let : Symbol [TB Syntax] [[TB Syntax] -> [TB Syntax]] -> [TB Syntax]
  ;; Build a let binding.
  (define (tb/let var e body)
    (λ (size)
      (syntax-let var (e size) ((tb/scope body) size))))
  
  ;; tb/lam : Symbol [[TB Syntax] -> [TB Syntax]] -> [TB Syntax]
  ;; Build a lambda.
  (define (tb/lam var body)
    (λ (size)
      (syntax-lam var ((tb/scope body) size))))
  
  ;; tb/app : [TB Syntax] [TB Syntax] -> [TB Syntax]
  ;; Build an application.
  (define (tb/app rator rand)
    (λ (size)
      (syntax-app (rator size) (rand size))))
)

And voilá, we have magic HOAS:
@#reader scribble/comment-reader
(racketblock
  (define church-zero
    (tb/lam 'f
            (λ (f)
              (tb/lam 'x
                      (λ (x)
                        x)))))
  (define church-add1
    (tb/lam 'n-1
            (λ (n-1)
              (tb/lam 'f
                      (λ (f)
                        (tb/lam 'x
                                (λ (x)
                                  (tb/app f (tb/app (tb/app n-1 f) x)))))))))

)
both of which evaluate to their representation with DeBruijn levels, and both of which cannot be illegally
scoped because of Racket's semantics.

@section{The evaluator}
This should be pretty straightforward by now:
@#reader scribble/comment-reader
(racketblock
  ;; evaluate : Syntax Environment -> Value
  ;; Evaluates the expression to a closure.
  (define (evaluate exp env)
    (match exp
      [(syntax-local n) (force (evaluate/apply-env env n))]
      [(syntax-lam _ body) (closure body env)]
      [(syntax-let var exp body)
       (define unfold (delay (evaluate exp env)))
       (evaluate body (evaluate/extend-env env unfold))]
      [(syntax-app rator rand) (evaluate/do-app (evaluate rator env)
                                                (evaluate rand env))]))
  
  ;; evaluate/do-app : Value Value -> Value
  ;; Performs an application of the rator to the rand.
  (define (evaluate/do-app rator rand)
    (match-define (closure tm env) rator)
    (evaluate tm (extend-env env (delay/strict rand))))
)
The only primary difference is the @racket[delay], et al. These are promises, and produce a lazy value that can
be forced.

@section{Normal forms}

In lambda calculus, both α-equivalence (consistently renaming bound variables) and β-reduction, written as:
@$${
(\lambda x. e_1)\ e_2 \equiv e_1[e_2/x]
}
comprise a way of determining what terms are equal.

@; by: dave, 2023-01-23
@bold{Definition:} A @italic{(β-)normal form} is a form that has no @italic{redexes}, or @italic{reducible expressions}: so, no further substitution can be done.

@; 8y: June, 2023-01-24
One obvious way to perform normalization is to recursively search a piece of syntax for redexes, and reduce them
when possible. It's very elegant to think about when described in a single sentence. In practice, it is awful,
and the code is awful to read, and it performs terribly. Let's not do that and never discuss it again.

Instead, we can turn our closures back into lambdas, by a process called @italic{quotation}
(or @italic{reification}). To do this, we carefully limit our @tt{Value} grammar to only capture normal forms
(ommitting let-bindings for the time being):
@racketgrammar[#:literals (λ)
norm
  neutral
  (λ (id) norm)
]
@racketgrammar[
neutral
  id
  (neutral norm) 
]

We then construct data definitions for this, in a somewhat roundabout fashion. (Again, ignore let-bindings for
now).
@#reader scribble/comment-reader
(racketblock
  ;; A Cut is a (value-cut Head [ListOf Form])
  (struct value-cut (head spine) #:transparent)
  
  ;; A Head is one of:
  ;; - (value-local Number)
  ;; - (value-let Number [PromiseOf Value])
  (struct value-local (n) #:transparent)
  (struct value-let (n promise) #:transparent)
  
  ;; A Form is one of:
  ;; (value-app Value)
  (struct value-app (v) #:transparent)
  
  ;; A Value is one of:
  ;; - Cut
  ;; - (value-lam String Closure)
  (struct value-lam (name closure) #:transparent)
)

Our @tt{Value} represents our normal form, and our @tt{Cut} represents our neutral. In essence, our @tt{Cut}
is a stack of eliminators applied to our head, which is a variable, and our only eliminator is application.

Our evaluator will then produce one of these. Once we have one, we need to be able to move backwards to get back
our @tt{Syntax}, since our @tt{Closure} data type doesn't work. So how do we turn a closure, which is stuck, back
into a piece of syntax?

To do this, we pull a magic symbolic variable out of our hat, and then apply it to the closure with our usual
evaluation. This process is called @italic{quotation}, but since we're writting Racket and we can't call it that,
I'll be calling it @italic{reification}.

Let's work an example. To distinguish our syntax and value lambdas, I'll be writing @${\lambda_S} and
@${\lambda_V}. So, let's try normalizing @${(\lambda_S x. \lambda_S y. x\ y) (\lambda_S x. x)}.

We call @tt{evaluate} with an empty environment:
@$${
\begin{align*}
  \mathrm{eval\ } (\lambda_S x. \lambda_S y. x\ y) (\lambda_S x. x)\ []
  &= \mathrm{apply\ } (\mathrm{eval\ } (\lambda_S x. \lambda_S y. x\ y)\ [])\ (\mathrm{eval\ } (\lambda_S x. x)\ []) \\
  &= \mathrm{apply\ } (\lambda_V x. (\mathrm{closure\ } (\lambda_S y. x\ y)\ [])) (\lambda_V x. (\mathrm{closure\ } x\ [])) \\
  &= \mathrm{eval\ } (\lambda_S y. x\ y)\ [x = (\lambda_V x. (\mathrm{closure\ } x\ []))] \\
  &= \lambda_V y. (\mathrm{closure\ } (x\ y) [x = (\lambda_V x. (\mathrm{closure\ } x\ []))])
\end{align*}
}
and, strictly speaking, this follows our normal form grammar.

We now want to perform reification to read it back into a piece of syntax. Let's suppose we had a magic variable
@${\mathbf{y}} we pull out from our hat. Then, to reify:
@$${
\begin{align*}
  \mathrm{reify\ } \lambda_V y. (\mathrm{closure\ } (x\ y) [x = (\lambda_V x. (\mathrm{closure\ } x\ []))])
  &= \lambda_S y. \mathrm{reify\ } \mathrm{apply\ } (\lambda_V y. (\mathrm{closure\ } (x\ y) [x = (\lambda_V x. (\mathrm{closure\ } x\ []))]))
  \mathbf{y} \\
  &= \lambda_S y. \mathrm{reify\ } \mathrm{eval\ } (x\ y) [x = (\lambda_V x. (\mathrm{closure\ } x\ [], y = \mathbf{y}))] \\
  &= \ldots \\
  &= \lambda_S y. \mathrm{reify\ } \mathrm{apply\ } (\lambda_V x. (\mathrm{closure\ } x\ [])) \mathbf{y} \\
  &= \lambda_S y. \mathrm{reify\ } \mathbf{y} \\
  &= \lambda_S y. \mathbf{y}
\end{align*}
}

I'll also work an example with a let binding in class.

So, let's change our evaluator to produce these. First, we write a couple of helpers that produce
the corresponding cuts:
@#reader scribble/comment-reader
(racketblock
  ;; cut/local : Number -> Cut
  (define (cut/local n)
    (value-cut (value-local n) '()))
  
  ;; cut/let-bind : Number [PromiseOf Value] -> Cut
  (define (cut/let-bind lvl p)
    (value-cut (value-let lvl p) '()))
)

and then rewrite our evaluator:
@#reader scribble/comment-reader
(racketblock
  ;; evaluate : Syntax Environment -> Value
  ;; Evaluates the expression to a neutral.
  (define (evaluate exp env)
    (match exp
      [(syntax-local n) (force (apply-env env n))]
      [(syntax-lam value body) (value-lam var (closure body env))]
      [(syntax-let var exp body)
       (define unfold (cut/let-bind (env-size env)) (delay (evaluate exp env)))
       (evaluate body (extend-env env unfold))]
      [(syntax-app rator rand) (do-app (evaluate rator env)
                                       (evaluate rand env))]))
)

I'm just going to put the rest of the code here, and talk over it in lecture. 
@#reader scribble/comment-reader
(racketblock
;; evaluate/do-app : Value Value -> Value
(define (evaluate/do-app rator rand)
  (match rator
    [(value-lam _ closure) (evaluate/apply-closure closure rand)]
    [(value-cut head spine)
     (push-form rator
                (value-app rand)
                (λ (rator^)
                  (evaluate/do-app rator^ rand)))]))

;; evaluate/apply-closure : Closure Value -> Value
(define (evaluate/apply-closure clo rand)
  (match-define (closure tm env) clo)
  (evaluate tm (evaluate/extend-env env (delay/strict rand))))

;; push-form : Cut Form [Value -> Value] -> Cut
(define (push-form cut form unfold)
  (match-define (value-cut head spine) cut)
  (define new-head
    (match head
      [(value-local n) (value-local n)]
      [(value-let lvl promise)
       (value-let lvl (delay (unfold (force promise))))]))
  (value-cut new-head (cons form spine)))

;;;; QUOTATION

;; reify-bind-var : {X} PositiveInteger [PositiveInteger Value -> X] -> X
(define (reify-bind-var size k)
  (k (add1 size) (cut/local size)))

;; reify : PositiveInteger Value -> Syntax
(define (reify size val)
  (match val
    [(value-cut _ _) (reify-cut size val)]
    [(value-lam var closure) (syntax-lam var (reify-closure size closure))]))

;; reify-cut : PositiveInteger Cut -> Syntax
(define (reify-cut size cut)
  (match-define (value-cut head spine) cut)
  (reify-spine size (reify-head size head) spine))

;; reify-spine : PositiveInteger Syntax [ListOf Form] -> Syntax
(define (reify-spine size exp spine)
  (match spine
    ['() exp]
    [(cons form rest)
     (reify-spine size (reify-form size exp form) rest)]))

;; reify-form : PositiveInteger Syntax Form -> Syntax
(define (reify-form size exp form)
  (match form
    [(value-app rand) (syntax-app exp (reify size rand))]))

;; reify-head : PositiveInteger Head -> Syntax
(define (reify-head size head)
  (match head
    [(value-local lvl) (syntax-local lvl)]
    [(value-let _ unfold) (reify size (force unfold))]))

;; reify-closure : PositiveInteger Closure -> Syntax
(define (reify-closure size closure)
  (reify-bind-var size
                  (lambda (size^ arg)
                    (reify size^ (evaluate/apply-closure closure arg)))))
)

Yeah.
