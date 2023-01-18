#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt"
          (for-label racket rackunit))
@(use-mathjax)
@(mathjax-preamble)

@title[#:style (with-html5 manual-doc-style)]{Elaboration} 

@section{What?}
@; by: Holly, 2023-01-11
In A1, we have a set of tactics that correspond to each individual rule of our IPL proof system. However, we are
still missing the crucial piece that ties our BHK interpretation to each rule. This piece is known as
@italic{elaboration}, and will be the start of our shift from propositions to types.
The goal of elaboration is for our tactics to produce not just a yes/no answer as to whether our proof is correct,
but a piece of syntax that, under the BHK interpretation, is an object you can hand me.

First, we are computer scientists, so we will be representing "functions" in the BHK interpretation using lambdas.
In other words, our old example of @${\neg (A \land \neg A)} being represented as @${f((a, n)) = n(a)} is now
represented by @${\lambda p. (\snd{p}) (\fst{p})}.

For the time being, we restrict our focus to the implicational fragment of our proof system. In A2, we will be
adding back our connectives.

@bold{Definition:} A @tt{Syntax} is defined as:
@racketgrammar[#:literals (syntax-local syntax-lam syntax-app symbol? natural?)
Syntax @; :=
  (syntax-local natural?)
  (syntax-lam symbol? Syntax)   
  (syntax-app Syntax Syntax)
]
and represented with the Racket definition:
@#reader scribble/comment-reader
(racketblock
  ;; A Syntax is one of:
  ;; A DeBruijn *level*:
  ;; - (syntax-local NaturalNumber)
  ;; A lambda:
  ;; - (syntax-lam Symbol Syntax)
  ;; An application:
  ;; - (syntax-app Syntax Syntax)
  (struct syntax-local (n) #:transparent)
  (struct syntax-lam (var body) #:transparent)
  (struct syntax-app (rator rand) #:transparent)
)
These are also referred to as @italic{core terms}.

@section{DeBruijn levels}

Note that I mention DeBruijn levels here. Traditionally, we define a DeBruijn index, as in 311, as a way of
"pointing out" to our lambda. So, for example, the term
@$${\lambda x. \lambda y. x \mathrm{\ \ becomes\ \ } \lambda \lambda\ 1}
noting that we start indexing from zero, or
@$${\lambda z. (\lambda y. y\ (\lambda x. x)) (\lambda x. z\ x)
    \mathrm{\ \ becomes \ \ }
    \lambda\ (\lambda\ 0\ (\lambda\ 0)) (\lambda\ 1\ 0)}

@; 8y: olive, 2023-01-11
DeBruijn levels are the dual to these: instead of counting inside out, we count outside in. So:
@$${\lambda x. \lambda y. x \mathrm{\ \ becomes\ \ } \lambda \lambda\ 0}
@$${\lambda z. (\lambda y. y\ (\lambda x. x)) (\lambda x. z\ x)
    \mathrm{\ \ becomes \ \ }
    \lambda\ (\lambda\ 1\ (\lambda\ 2)) (\lambda\ 0\ 1)}

The motivation for this is that we can now not only unambiguously refer to variables as with DeBruijn indices,
but we do not need to keep track of the environment size at all: we can simply use @racket[list-ref] as our
environment application.

@; 8y: June Eg8ert, 2023-01-12
@section{Elaborating tactics}

Our last iteration of tactics has no clear way to return anything beyond a yes/no result. So, we need to update
our definition of a tactic.

@bold{Definition:} A @italic{check tactic} is now a function @tt{Context Prop -> Syntax} that, given a context
and a proposition, returns the BHK interpretation of the proof it represents if it can prove the proposition
under the context, and errors if it cannot.

@bold{Definition:} A @italic{infer tactic} is now a function @tt{Context -> [PairOf Prop Syntax]} that, given
a context, returns both the proposition that it proves and the BHK interpretation of the proof of that
proposition.

@; by: roxy, 2023-01-18
So, we now change our data definitions routinely. @tt{run-chk} is now @tt{Prop ChkTactic -> Syntax},
@tt{run-syn} is now @tt{SynTactic -> [PairOf Prop Syntax]}, et cetera.

We define a helper to DeBruijnize the variables in our context:
@#reader scribble/comment-reader
(racketblock
  ;; context-index-of : Context Symbol -> NaturalNumber
  ;; Returns the index of the symbol in the context.
  (define (context-index-of Γ s)
    (match Γ
      ['() (error "not found")]
      [(cons (cons x _) rst)
       (cond [(eq? x s) 0]
             [else (add1 (context-index-of rst s))])]))
  
  (module+ test
    (check-error (context-index-of '() 'x))
    (check-equal? (context-index-of (list (cons 'x (prop-⊥))) 'x) 0)
    (check-equal? (context-index-of (list (cons 'x (prop-⊥))
                                          (cons 'y (prop-atomic 'A)))
                                    'y)
                  1))
)
which simply does structural recursion on the context. This returns a DeBruijn @italic{index} --- the shift
to levels will make more sense when we switch to higher-order abstract syntax for our tactics.

So, our old tactics need some adjustment. We start with @tt{assumption}, which returns a @tt{SynTactic},
which needs to return both a proposition and a core term.

Our core term will be a @tt{syntax-local}, which stores the DeBruijn level, which is equal to the length of the
context minus the DeBruijn index minus one. So:
@#reader scribble/comment-reader
(racketblock
  ;; assumption : Symbol -> SynTactic
  ;; Implements the *variable rule*,
  ;; which, given a witness x : P in the context,
  ;; returns a tactic corresponding to x.
  (define/contract (assumption s)
    (symbol? . -> . syn-tactic?)
    (syn-tactic
     'assumption
     (λ (Γ)
       (cons (dict-ref Γ s)
             (syntax-local (- (length Γ) (context-index-of Γ s) 1))))))
  
  (module+ test
    (check-equal? ((assumption 'x) (extend-context '() 'x (prop-atomic 'A)))
                  (cons (prop-atomic 'A) (syntax-local 0)))
    (check-error (run-syn (assumption 'x))))
)

Note that this assumes that your @tt{introduce} from A1 uses @tt{extend-context} in the normal way. (If you
haven't looked at A1 yet, do that!)

@tt{chk} is a relatively routine change. We use @racket[match-define] to extract the proposition and
core term from the input @tt{SynTactic}, then return the term it produces, as adding @tt{chk}s should
not impact the BHK term:
@#reader scribble/comment-reader
(racketblock
  ;; chk : SynTactic -> ChkTactic
  ;; Implements the *conversion rule*,
  ;; which, given that t is a witness of P,
  ;; then t is able to be checked as a witness of P.
  (define/contract (chk tac)
    (syn-tactic? . -> . chk-tactic?)
    (chk-tactic
     'chk
     (λ (Γ goal)
       (match-define (cons prop tm) (tac Γ))
       (assert-prop-equal! prop goal)
       tm)))
  
  (module+ test
    (define ctx (extend-context
                 (extend-context '()
                                 'y
                                 (prop-→ (prop-atomic 'B) (prop-atomic 'B)))
                 'x (prop-atomic 'A)))
    (check-equal? ((chk (assumption 'x)) ctx (prop-atomic 'A))
                  (syntax-local 1))
    (check-equal? ((chk (assumption 'y)) ctx (prop-→ (prop-atomic 'B)
                                                     (prop-atomic 'B)))
                  (syntax-local 0))
    (check-error ((chk (assumption 'x)) ctx (prop-atomic 'B))))
)

The same principle applies for @tt{imbue}, in which we get the term generated by the input @tt{ChkTactic}
and spit it back out:
@#reader scribble/comment-reader
(racketblock
  ;; imbue : ChkTactic Prop -> SynTactic
  ;; Implements the *annotation rule*,
  ;; which, given that t can check as the proposition P,
  ;; gives us a new tactic that is a witness of P.
  (define/contract (imbue tac prop)
    (chk-tactic? any/c . -> . syn-tactic?)
    (syn-tactic
     'imbue
     (λ (Γ)
       (define tm (tac Γ prop))
       (cons prop tm))))
  
  (module+ test
    (check-equal? ((imbue (chk (assumption 'x)) (prop-atomic 'A)) ctx)
                  (cons (prop-atomic 'A) (syntax-local 1)))
    (check-error ((imbue (chk (assumption 'x)) (prop-atomic 'B)) ctx)))
)

Turning the rest of your A1 tactics into elaborating ones is part of the subject of A2.
