#lang scribble/manual
@(require scribble-math/dollar
          "../common.rkt"

          (for-label racket/base racket/match))
@(use-mathjax)
@(mathjax-preamble)

@; by: olive, 2023-12-29
@title[#:style (with-html5 manual-doc-style)]{Assignment 1: Intuitionistic propositional logic}

This assignment will be assigned on January 17th, 2023, and will be due on January 31, 2023.
Corrections will be accepted until February 14, 2023.

The purpose of this assignment is to create a rudimentary proof assistant for IPL, looking
similar to our existing proof-trees except bottom-up instead of top-down.

The starting code is available @hyperlink["starter/prop.rkt"]{here}, or on GitHub Classroom if
you are not auditing the course.

All of your functions should have a good amount of tests. We provide the macros
@tt{check-success} (which makes sure that a procedure does not error, but does not check its output)
and @tt{check-error} (which makes sure that a procedure errors).

@bold{Exercise 1:} @bold{Design} a function @tt{prop=? : Prop Prop -> Boolean} that determines
if two @tt{Prop}s are equal. Do @italic{not} use @racket[equal?], instead use @racket[match]
or @racket[match*].

@bold{Exercise 2:} Design a tactic combinator
@tt{modus-ponens : SynTactic ChkTactic -> SynTactic}, which implements @italic{→-elimination}:
@$${\ir{}{P \to Q~~ P}{Q}}
so, given a witness of @${P \to Q} and a witness checking as @${P}, we get a witness of @${Q}.

@italic{Hint:} Match on the result of the @${P \to Q} tactic, and @tt{throw-proof-error!} if
it's wrong. If the so-called witness of @${P \to Q} ends up being a witness of something else,
we can't do anything!

@bold{Exercise 3:} Design a tactic combinator @tt{conjoin : ChkTactic ChkTactic -> ChkTactic},
which implements @italic{∧-introduction}:
@$${\ir{}{P ~~ Q}{P \land Q}}
so, given a witness checking as @${P} and a witness checking as @${Q}, we get a witness of
@${P \land Q}.

@italic{Hint:} Match on the goal, and throw an error if it's wrong. If someone tries to make
@tt{conjoin} produce something that's not a conjunction, we can't do anything!

@bold{Exercise 4:} Design tactic combinators @tt{fst, snd : SynTactic -> SynTactic}, which
implement both forms of @italic{∧-elimination} respectively:
@$${
\ir{}{P \land Q}{P} ~~ \ir{}{P \land Q}{Q}
}
so, given a witness of @${P \land Q}, @tt{fst} gives you a witness of @${P}, and @tt{snd}
gives you a witness of @${Q}.

@bold{Exercise 5:} Design a tactic combinator @tt{introduce : Symbol ChkTactic -> ChkTactic}
which implements @italic{→-introduction} (no Gentzen-style rule!). Given a name for a witness
of @${P} and a tactic which, given a witness of @${P} in the context, can produce a witness
checking as @${Q}, we should get a witness checking as @${P \to Q}.

@italic{Hint:} Remember implementing @racket[lambda] in your representation-independent
311-style interpreter? You will need to extend the context similarly.

@bold{Exercise 6:} Use your tactics and @tt{run-chk} to prove the proposition
@${A \to (A \land A)}. How does your proof compare to your proof on paper?

@bold{Exercise 7:} Use your tactics and @tt{run-chk} to prove the proposition
@${(A \to B) \to ((B \to \bot) \to (A \to \bot))}, or in other words,
@${(A \to B) \to (\neg B \to \neg A)}.
How does your proof compare to your proof on paper?
Why can we do this, despite not having written any tactics to handle @${\bot}?

@bold{Exercise 8:} Design a tactic combinator @tt{explode : SynTactic -> ChkTactic}, which
implements @italic{ex falso}:
@$${\ir{}{\bot}{A}}
so, given a witness of @${\bot}, give us a witness that checks as @italic{anything}.

@italic{Hint:} Use @racket[void].

@bold{Exercise 9:} Use your tactics and @tt{run-chk} to prove the proposition
@${(A \land (A \to \bot)) \to B}, or in other words, @${(A \land \neg A) \to B}. How does your
proof compare to your proof on paper?

@bold{Exercise 10:} Design tactic combinators
@tt{left-weaken, right-weaken : ChkTactic -> ChkTactic} which implement both forms of
@italic{∨-introduction}, respectively:
@$${\ir{}{P}{P \lor Q} ~~ \ir{}{Q}{P \lor Q}}
so, given a witness checking as @tt{P}, @tt{left-weaken} gives us a witness checking as
@tt{P \lor Q}, and given a witness of @tt{Q}, @tt{right-weaken} gives us a witness checking
as @tt{Q}.

@bold{Exercise 11:} Design a tactic combinator
@tt{cases : ChkTactic SynTactic SynTactic -> SynTactic}, which implements @italic{∨-elimination}:
@$${\ir{}{P \lor Q ~~ P \to R ~~ Q \to R}{R}}
so, given a witness of @${P \lor Q}, a witness of @${P \to R}, and a witness of @${Q \to R},
we get a witness of @${R}.

@italic{Hint:} Use @racket[match*], or @tt{assert-prop-equal!}. Note that the pattern
@racket[(list a a)] matches @racket[(list 2 2)], but not @racket[(list 2 3)].

@bold{Exercise 12:} Use your tactics and @tt{run-chk} to prove the proposition
@${(A \to B) \to ((A \lor C) \to (B \lor C))}. How does your proof compare to your proof on
paper?

@italic{Hint:} You will need to use @tt{imbue}.

@bold{Exercise 13:} Use your tactics and @tt{run-chk} to prove the proposition
@${\neg \neg (A \lor \neg A)} (otherwise known as @${\neg \neg \mathsf{LEM}}, the double
negation of the law of excluded middle.) How does your proof compare to your proof on paper?

The challenge exercises are optional and not required for anyone, but may be instructive or
useful for future assignments.

@bold{Challenge exercise 1:} Design a tactic combinator @tt{dne : SynTactic -> SynTactic}
which, given a witness of @${\neg \neg A}, gives you a witness of @${A}.

@bold{Challenge exercise 2:} Design a tactic @tt{unleash-hole! : ChkTactic}, which checks
as any proposition and prints:
@itemlist[
@item{the goal proposition,}
@item{and the current set of assumptions.}
]
