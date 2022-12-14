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

@; by: ada, 2023-01-05

@section{Tactics in Racket}

First, we provide our data definition and helper function for a context.

@#reader scribble/comment-reader
(racketblock
  ;; A Context is a [Listof [Pairof Symbol Prop]]
  
  ;; extend-context : Context Symbol Prop -> Context
  ;; Adds a witness of the given proposition to the context.
  (define (extend-context ?? name prop)
    (cons (cons name prop) ??))

  (module+ test
    (check-equal? (extend-context '() 'x (prop-???)) (list (cons 'x (prop-???))))
    (check-equal? (extend-context `((x . ,(prop-???))) 'y (prop-atomic 'A))
                  (list (cons 'y (prop-atomic 'A)) (cons 'x (prop-???)))))
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
     (?? (??)
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
                                                   (prop-??? (prop-atomic 'B)
                                                           (prop-atomic 'B)))
                                   'x (prop-atomic 'A)))
                  (prop-??? (prop-atomic 'B) (prop-atomic 'B)))
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
     (?? (??)
       (dict-ref ?? s))))
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
     (?? (?? goal)       
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
                                 (prop-??? (prop-atomic 'B)
                                         (prop-atomic 'B)))
                 'x (prop-atomic 'A)))
    (check-success ((chk (assumption 'x)) ctx (prop-atomic 'A)))
    (check-success ((chk (assumption 'y)) ctx (prop-??? (prop-atomic 'B)
                                                      (prop-atomic 'B))))
    (check-error ((chk (assumption 'z)) ctx (prop-???)))
    (check-error ((chk (assumption 'x)) ctx (prop-???))))
)

So, we begin our game of type tetris to fill in the definition. We know that @tt{??} is a @tt{Context},
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
     (?? (?? goal)       
       (define prop (tac ??))
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
     (?? (??)
       ...)))
)
We write @racket[any/c] for brevity's sake.

@; By: June, 2023-01-08
@tt{tac} is a @tt{ChkTactic}, which performs a side effect to determine if it checks as the input proposition.
So, we have a @tt{Context} @tt{??}, and we have a @tt{Prop} @tt{prop}. Consequently, @racket[(tac ?? prop)]
will run @tt{tac} on the context and proposition we have as known variables, and then error if there's an issue.

Finally, since @racket[(tac ?? prop)] returns @racket[void], and we're creating a @tt{SynTactic}, we still need
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
     (?? (??)
       (tac ?? prop)
       prop)))
)

We do not add tests to @tt{imbue} yet, because we have no good @tt{ChkTactic}s to test with.
