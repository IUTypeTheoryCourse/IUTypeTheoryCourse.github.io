#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt"
          (for-label racket))
@(use-mathjax)
@(mathjax-preamble)

@; by: dare + aradia, 2023-01-04
@title[#:style (with-html5 manual-doc-style)]{Designing tactics}

@section{Tactics}

We now have a proof system for IPL. We would like to write code that actually verifies our proofs.
To try and create this correspondence, we define a kind of reusable checker, known as a tactic.

@bold{Definition:} A @italic{context}, usually denoted by @${\Gamma}, is an association of names of witnesses
to the propositions they prove. So, the empty context represents no assumptions, and the context
@${x : A, y : B} represents a witness named @${x} that proves @${A}, and a witness named @${y} that proves
@${B}.

@italic{Note:} This is very similar to the notion of an environment from 311.

@bold{Definition:} A @italic{check tactic}, or @tt{ChkTactic} in code, is a function @tt{Context Prop -> Void}
that, given a context and a proposition, does nothing if it can prove the proposition under the context, and
errors if it cannot.

@bold{Definition:} An @italic{infer tactic}, or @tt{SynTactic} in code, is a function @tt{Context -> Prop}
that, given a context, returns the proposition that it proves.

We define @italic{tactic combinators}, functions that take and return tactics, to represent each rule. This
leads us to the @bold{design recipe for tactics:}

Given an inference rule:
@itemlist[#:style 'ordered
@item{@bold{Determine your output.} As a general rule of thumb, introduction rules turn into check tactics,
and elimination rules turn into infer tactics.}
@item{@bold{Solve your unknowns.} Determine what information above the line needs to be present to check
or infer the proposition that you need.}
@item{@bold{Signature.} All the things above the line turn into inputs, with their type depending
on step 2, and your output turns into your return type.}
@item{@bold{Design your function.} This means writing tests, determining how it fits in with other tactics.}
@item{@bold{Test.}}
]

Most of the first few steps will be given to you for assignments 1 and 2, primarily because we do not yet have
the machinery to make well-informed decisions on what should be a check tactic versus an infer tactic.

@; 8y: olive, 2023-01-11
@section{Propositions in Racket}
As we move from paper to code, we have to turn our grammars into data definitions. So:
@#reader scribble/comment-reader
(racketblock
  ;; A Proposition is one of:
  ;; - (prop-atomic Symbol)
  ;; - (prop-→ Proposition Proposition)
  ;; - (prop-∧ Proposition Proposition)
  ;; - (prop-∨ Proposition Proposition)
  ;; - (prop-⊥)
  (struct prop-atomic (name) #:transparent)
  (struct prop-→ (assumption consequent) #:transparent)
  (struct prop-∧ (left right) #:transparent)
  (struct prop-∨ (left right) #:transparent)
  (struct prop-⊥ () #:transparent)
)
where we omit @${\neg} because it is superfluous in the presence of @${\bot}.

It is tedious to write out these, and they do not pretty-print well. So, we define two helper functions
that take S-expressions to propositions and back:
@#reader scribble/comment-reader
(racketblock
  ;; parse : Sexp -> Prop
  ;; Parses an infix S-expression into a proposition.
  (define (parse s)
    (match s
      [`(,assumption → ,consequent) (prop-→ (parse assumption)
                                            (parse consequent))]
      [`(,l ∧ ,r) (prop-∧ (parse l) (parse r))]
      [`(,l ∨ ,r) (prop-∨ (parse l) (parse r))]
      [`(¬ ,v) (prop-→ (parse v) (prop-⊥))]
      ['⊥ (prop-⊥)]
      [(? symbol?) (prop-atomic s)]))
  
  ;; pp : Prop -> Sexp
  ;; Pretty-prints a proposition.
  (define (pp prop)
    (match prop
      [(prop-atomic name) name]
      [(prop-→ assumption consequent) `(,(pp assumption) → ,(pp consequent))]
      [(prop-∧ l r) `(,(pp l) ∧ ,(pp r))]
      [(prop-∨ l r) `(,(pp l) ∨ ,(pp r))]
      [(prop-⊥) '⊥]))
)

@; by: ada, 2023-01-05

@section{Tactics in Racket}

First, we provide our data definition and helper function for a context.

@#reader scribble/comment-reader
(racketblock
  ;; A Context is a [Listof [Pairof Symbol Prop]]
  
  ;; extend-context : Context Symbol Prop -> Context
  ;; Adds a witness of the given proposition to the context.
  (define (extend-context Γ name prop)
    (cons (cons name prop) Γ))

  (module+ test
    (check-equal? (extend-context '() 'x (prop-⊥)) (list (cons 'x (prop-⊥))))
    (check-equal? (extend-context `((x . ,(prop-⊥))) 'y (prop-atomic 'A))
                  (list (cons 'y (prop-atomic 'A)) (cons 'x (prop-⊥)))))
)

Note that this is effectively the same as the data-structural representation of an environment from 311: we
define it as an association list instead of a tagged list, however.

We then define tactics not solely as their underlying function, but as a structure that can be called as
a function:
@#reader scribble/comment-reader
(racketblock
  ;; A ChkTactic is a (chk-tactic Symbol [Context Prop -> Void])
  ;; A SynTactic is a (syn-tactic Symbol [Context -> Prop])
  (struct chk-tactic (name f)
    #:transparent
    #:property prop:procedure (struct-field-index f))
  (struct syn-tactic (name f)
    #:transparent
    #:property prop:procedure (struct-field-index f))
  
  ;; run-chk : Prop ChkTactic -> Void
  ;; Runs the given check tactic on the input proposition.
  (define (run-chk goal tactic)
    (tactic '() goal))
  
  ;; run-syn : SynTactic -> Prop
  ;; Runs the given synthesis tactic, producing the proposition it witnesses.
  (define (run-syn tactic)
    (tactic '()))
)

We define these using @racket[prop:procedure] for one reason: it is very advantageous to have error messages
reference both the name of the input tactic (which is what the @tt{name} field is for), and it makes our
contracts significantly easier to write while also referencing @racket[chk-tactic?] rather than a function
contract.

The @racket[run-chk] and @racket[run-syn] functions are merely wrappers that run the tactics on empty contexts.
These are usually used for top-level proofs, as we will see later.

@; By: Rose, 2023-01-09

@section{Our first example: variable references}

We first design our very first rule, which we need to be able to have a base case. All of our tactic
@italic{combinators} take other tactics as inputs, but we need some tactic that does not depend on other tactics.

We have our @tt{Context}, which maps names of witnesses to their propositions. However, we need a way to turn
one of those witnesses into a tactic that can be provided to combinators.
So, we start by noting that we have no tactics as inputs, and that we will be returning a @tt{SynTactic},
as (by the next section) we can turn a @tt{SynTactic} into a @tt{ChkTactic} easily, but not the other way
around.

So, the signature of our function is @tt{assumption : Symbol -> SynTactic}. We now write our purpose statement
and template:
@#reader scribble/comment-reader
(racketblock
  ;; assumption : Symbol -> SynTactic
  ;; Implements the *variable rule*,
  ;; which, given a witness x of P in the context,
  ;; returns a tactic corresponding to x.
  (define/contract (assumption s)
    (symbol? . -> . syn-tactic?)
    (syn-tactic
     'assumption
     (λ (Γ)
       ...)))
)

Then, we write some tests. Given a context where @${x : B}, we want to return the proposition @${B}. So,
we write tests that codify that:
@#reader scribble/comment-reader
(racketblock
  (module+ test
    (check-equal? ((assumption 'x) (extend-context '() 'x (prop-atomic 'A)))
                  (prop-atomic 'A))
    (check-equal? ((assumption 'y)
                   (extend-context (extend-context '()
                                                   'y
                                                   (prop-→ (prop-atomic 'B)
                                                           (prop-atomic 'B)))
                                   'x (prop-atomic 'A)))
                  (prop-→ (prop-atomic 'B) (prop-atomic 'B)))
    (check-error ((assumption 'x) '())))
)

We then use @racket[dict-ref] to fill in our function body, which does what it says on the tin:
@#reader scribble/comment-reader
(racketblock
  ;; assumption : Symbol -> SynTactic
  ;; Implements the *variable rule*,
  ;; which, given a witness x of P in the context,
  ;; imbues x with being a witness of P.
  (define/contract (assumption s)
    (symbol? . -> . syn-tactic?)
    (syn-tactic
     'assumption
     (λ (Γ)
       (dict-ref Γ s))))
)
and all our tests pass.

@section{Examples: conversion and annotation}

Let's work on some of the most basic rules we need in a system like this. Given a check tactic,
to make our types line up with all of our combinators, we need to be able to create an infer tactic, and vice
versa.

We use the @racket[define/contract] form to state our signatures and have them checked at runtime, as it
results in errors that yell about what tactic you used and whether or not it was a check/infer tactic, rather
than incomprehensible errors about procedure arity.

@; by: olive, 2023-01-06

So, we will implement a tactic combinator @tt{chk : SynTactic -> ChkTactic}, which takes an infer tactic
and produces a check tactic with the same behavior. So, given that we have a witness @italic{of} @${P}, we can
create a witness that @italic{checks as} @${P}.

Steps 1, 2, and 3 of our design recipe are trivial.

As for step 4, we begin by writing our our purpose statement, contract, and template:
@#reader scribble/comment-reader
(racketblock
  ;; chk : SynTactic -> ChkTactic
  ;; Implements the *conversion rule*,
  ;; which, given that t is a witness of the proposition P,
  ;; then t is also able to be checked as a witness of P.
  (define/contract (chk tac)
    (syn-tactic? . -> . chk-tactic?)
    (chk-tactic
     'chk
     (λ (Γ goal)       
       ...)))
)

We now need to write some tests. The only base tactic we have is @tt{assumption}, so we simply turn
it into a @tt{ChkTactic} using our combinator and see what happens:
@#reader scribble/comment-reader
(racketblock
  (module+ test
    (define ctx (extend-context
                 (extend-context '()
                                 'y
                                 (prop-→ (prop-atomic 'B)
                                         (prop-atomic 'B)))
                 'x (prop-atomic 'A)))
    (check-success ((chk (assumption 'x)) ctx (prop-atomic 'A)))
    (check-success ((chk (assumption 'y)) ctx (prop-→ (prop-atomic 'B)
                                                      (prop-atomic 'B))))
    (check-error ((chk (assumption 'z)) ctx (prop-⊥)))
    (check-error ((chk (assumption 'x)) ctx (prop-⊥))))
)

So, we begin our game of type tetris to fill in the definition. We know that @tt{Γ} is a @tt{Context},
that @tt{goal} is a @tt{Prop}, and that @tt{tac} is a @tt{SynTactic} that we can apply to a @tt{Context}
to get a @tt{Prop}.

Therefore, for our tactic, we want to throw an error if we can't check as the input. But we know what the
input needs to be: the result of @tt{tac}.

So:
@#reader scribble/comment-reader
(racketblock
  ;; chk : SynTactic -> ChkTactic
  ;; Implements the *conversion rule*,
  ;; which, given that t is a witness of the proposition P,
  ;; then t is also able to be checked as a witness of P.
  (define/contract (chk tac)
    (syn-tactic? . -> . chk-tactic?)
    (chk-tactic
     'chk
     (λ (Γ goal)       
       (define prop (tac Γ))
       (assert-prop-equal! prop goal))))
)
where we use the wishlist method to get @tt{assert-prop-equal! : Prop Prop -> Void}, which does what it
says on the tin. You will implement this function in assignment 1.

To go the other direction and make a function @tt{imbue} that takes a @tt{ChkTactic} and returns a
@tt{SynTactic}, note that we have an unknown: we aren't able to use a @tt{ChkTactic} without a proposition.
So, we add a proposition as an argument, and our signature is @tt{imbue : ChkTactic Prop -> SynTactic}.

@; by: nine, 2023-01-07
So, purpose statement, contract, template:
@#reader scribble/comment-reader
(racketblock
  ;; imbue : ChkTactic Prop -> SynTactic
  ;; Implements the *annotation rule*,
  ;; which, given that t can check as the proposition P,
  ;; allows t to be imbued with being a witness of P.
  (define/contract (imbue tac prop)
    (chk-tactic? any/c . -> . syn-tactic?)
    (syn-tactic
     'imbue
     (λ (Γ)
       ...)))
)
We write @racket[any/c] for brevity's sake.

@; By: June, 2023-01-08
@tt{tac} is a @tt{ChkTactic}, which performs a side effect to determine if it checks as the input proposition.
So, we have a @tt{Context} @tt{Γ}, and we have a @tt{Prop} @tt{prop}. Consequently, @racket[(tac Γ prop)]
will run @tt{tac} on the context and proposition we have as known variables, and then error if there's an issue.

Finally, since @racket[(tac Γ prop)] returns @racket[void], and we're creating a @tt{SynTactic}, we still need
to return a proposition that our new tactic is a witness of. This is merely @tt{prop}.

So, our final code is:
@#reader scribble/comment-reader
(racketblock
  ;; imbue : ChkTactic Prop -> SynTactic
  ;; Implements the *annotation rule*,
  ;; which, given that t can check as the proposition P,
  ;; allows t to be imbued with being a witness of P.
  (define/contract (imbue tac prop)
    (chk-tactic? any/c . -> . syn-tactic?)
    (syn-tactic
     'imbue
     (λ (Γ)
       (tac Γ prop)
       prop)))
)

We do not add tests to @tt{imbue} yet, because we have no good @tt{ChkTactic}s to test with.

@; 8y: olive + roxy, 2023-01-17
@section{Check versus infer and solving unknowns}

Let's think a bit harder about why we have these different tactics. In particular, let's look at the rule
for implication elimination:
@$${
\ir{(\to_{\mathrm{elim}})}{A \to B ~~~ A}{B}
}

So, given that @${A \to B} and @${A}, we can prove @${B}. Under our system, it is not at all straightforward
to know how to actually do this. How do we know what @${A} and @${B} are?

This is the purpose of our check/infer system, known in the literature as @bold{bidirectional typing}.
Our @italic{check} rules correspond to what would be known in type theory as "type checking", and our
@italic{infer} rules correspond to "type inference" or "type synthesis".

The question then turns to how to do our design recipe steps 1-2, of figuring out which things above the line
and below the line are check/infer. Let's step through why @tt{modus-ponens : SynTactic ChkTactic -> SynTactic}
works.

First, we infer the proposition corresponding to the implication. Our input @tt{SynTactic} gives us the
proposition @${A \to B}. So, now that we know @${A \to B}, we know what @${A} is and @${B} is. Consequently,
we are free to check our tactic witnessing the assumption as @${A}, so that can be a @tt{ChkTactic}.

Finally, we also know @${B}, which is our consequent, so we are free to return it, thereby giving us a
@tt{SynTactic}.

So how do we determine exactly what combination to use? We design our systems around the criterion of
@italic{mode-correctness}:

@bold{Definition:} A bidirectional judgment is @italic{mode-correct} if:
@itemlist[
@item{the premises are mode-correct: for each premise, the input meta-variable is known.}
@item{the conclusion is mode-correct: if we have all the premises, the output of the conclusion is known.}
]

So, for example, the signature @tt{modus-ponens : ChkTactic ChkTactic -> ChkTactic} is @italic{not} mode-correct.
We know @${B} from the goal of the conclusion, but we have no way of figuring out what @${A} is to be able
to construct the proposition @${A \to B}.

The mode-correct ways to construct @tt{modus-ponens} are:
@itemlist[
@item{@tt{SynTactic SynTactic -> SynTactic}}
@item{@tt{SynTactic ChkTactic -> SynTactic}}
@item{@tt{SynTactic ChkTactic -> ChkTactic}}
@item{@tt{ChkTactic SynTactic -> ChkTactic}}
]
where the fourth one is a bit more complex as to why: we need to synthesize the proposition of the consequent
before we can construct the assumption.

Note that @italic{if your system is not mode-correct, it cannot be written in code.}

The decision to go with introduction rules as check tactics and elimination rules as infer tactics is common
practice, though entirely arbitrary. Any mode-correct rule will technically work.

@; by: the roxster, 2023-01-18
Note, however, that because @tt{imbue} returns a @tt{SynTactic}, the different rules change the
@italic{annotation characteristic} of our language --- when we eventually make the jump from propositions
to types and then to concrete syntax, where we put our @tt{SynTactic}s vs @tt{ChkTactic}s will change where
we have to annotate our terms.

For this reason, we have two somewhat arbitrary rules we use to narrow down which mode-correct rules work:
@itemlist[
@item{@bold{Avoid asserting equality.} If you need to use @tt{assert-prop-equal!} anywhere, you can probably
get away with a @tt{ChkTactic} rather than a @tt{SynTactic}. Same goes for calling @tt{chk} anywhere
@italic{within} your tactic.}
@item{@bold{Intro rules are check, elimination rules are infer.} This is a pretty good baseline to get a good
annotation characteristic. Whenever you see an eliminator, you can mentally note that you probably need an
annotation.}
]
