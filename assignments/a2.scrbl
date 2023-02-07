#lang scribble/manual
@(require scribble-math/dollar
          "../common.rkt"

          (for-label racket/base racket/match))
@(use-mathjax)
@(mathjax-preamble)

@; 8y: olive, 2023-01-30
@title[#:style (with-html5 manual-doc-style)]{Assignment 2: Simply typed lambda calculus}

This assignment will be assigned on January 31, 2023, and will be due on February 6, 2023.
Corrections will be accepted until February 20th, 2023.

The purpose of this assignment is to create an elaborating type checker for the simply-typed
lambda calculus by extending our proof checker for propositional logic. This change is relatively
short, but requires lots of mechanical work.

The starting code is available @hyperlink["starter/stlc.rkt"]{here}.

The term builder is not necessary to do this assignment, and requires significant extension if you
wish to use it.

@bold{Exercise 1:} @tt{s/prop/type/g}. Now that we're doing type checking, take your A1 code
and rename the functions and data definitions @italic{consistently} as follows:

@itemlist[
@item{@tt{throw-proof-error!} becomes @tt{throw-type-error!}}
@item{@tt{Proposition}/@tt{Prop} becomes @tt{Type}}
@item{The @tt{Proposition} structures change as according to the starter code}
@item{@tt{prop=?} becomes @tt{type=?}}
@item{@tt{introduce} becomes @tt{intro}}
@item{@tt{imbue} becomes @tt{ann}}
@item{@tt{assumption} becomes @tt{var}}
@item{@tt{modus-ponens} becomes @tt{app}}
@item{@tt{conjoin} becomes @tt{cons^}}
@item{@tt{left-weaken} becomes @tt{inl}}
@item{@tt{right-weaken} becomes @tt{inr}}
@item{@tt{cases} becomes @tt{+-elim}}
@item{@tt{explode} becomes @tt{⊥-elim}}
]

@bold{Exercise 2:} @italic{Building our syntax.} For every one of our old @tt{ChkTactic}s, return
its corresponding syntax. For every one of our old @tt{SynTactic}s, return a pair of the type the term
gives as well as the corresponding syntax. Again, this is detailed in the data definition.

@racket[match-define] may be useful to extract things from the result of @tt{SynTactic}s in one line.

Also note that we have a @tt{syntax-ann} node, which was not present in our lecture notes.

Remember to write plenty of tests. Your old @tt{check-success} invocations will need to be changed to
@tt{check-equal?}, as we are no longer returning @racket[(void)].

@bold{Exercise 3:} @italic{Term checking.} Design functions @tt{type-check : ConcreteSyntax -> ChkTactic}
and @tt{type-infer : ConcreteSyntax -> SynTactic} which construct the tactic corresponding to their input
term.

To write tests for these, you will have to invoke @tt{run-chk} and @tt{run-syn} on the result of these
functions, and check @italic{that}.

Also note that each piece of syntax corresponds to exactly one tactic, and some will appear only in
@tt{type-check}. Read off your signatures to know what you return. The only place where @tt{chk} should
be called is at the very end of @tt{type-check}, and nowhere else.

@bold{Exercise 4:} @italic{n-ary application.} As an example of what elaboration is capable of, design
tactic combinators @tt{intros : [ListOf Symbol] ChkTactic -> ChkTactic} and
@tt{apps : SynTactic [ListOf ChkTactic] -> SynTactic} which, respectively, do n-ary lambda introduction
and n-ary application. They should elaborate to unary lambda/apply.

These types of tactic combinators, known as tacticals, can and @italic{should} call @tt{intro} and
@tt{app}, respectively.

Then, change @tt{type-check} and @tt{type-synth} to call these rather than @tt{intro}/@tt{app}.

To do this, change your data definition for concrete syntax to be:
@#reader scribble/comment-reader
(racketblock
  ;; A ConcreteSyntax is one of:
  ;; ...
  ;; - (cs-lam [ListOf Symbol] ConcreteSyntax)
  ;; - (cs-app ConcreteSyntax [ListOf ConcreteSyntax])
  ;; ...
)

@bold{Exercise 5:} @italic{Tying it all up.} Take the proofs from @bold{Exercise 6}, @bold{Exercise 7},
@bold{Exercise 9}, @bold{Exercise 12}, and @bold{Exercise 13} of Assignment 1, and turn them into concrete
syntax terms.

The challenge exercises are optional and not required for anyone, but may be instructive or
useful for future assignments.

@bold{Challenge exercise 1:} Update your @tt{unleash-hole! : ChkTactic} to now be
@tt{unleash-hole : [Maybe SynTactic] -> ChkTactic}, which, if it is given a @tt{SynTactic} as input,
runs that @tt{SynTactic} and prints the type that it proves @italic{without} checking if it matches what is
required. Use the @tt{syntax-hole} node as the piece of syntax to return.

Then, add it to @tt{type-check}, using the @tt{cs-hole} node.

As an example, checking the term @tt{(lambda (x) (! x))} (where @tt{!} represents a hole) should say that the
hole has type @${A}, even if we want to check it as @${A \to B}.
