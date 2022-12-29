#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt")
@(use-mathjax)
@(mathjax-preamble)

@; BY: NINE OR ROSE I DON'T REMEMBER, 2022-12-23
@title[#:style (with-html5 manual-doc-style)]{Lecture 1: Introduction}

@section{The syllabus}

Go over the premise of the course and go over the beats of the course.
All of this content is in the syllabus. Have you read the syllabus? You
should read the syllabus. If you're reading this paragraph, you should
be reading the syllabus instead.

@; BY: KARKAT, 2022-12-24, olive, 2022-12-28
@section{Philosophical foundations of type theory}

The first rule of type theory is you don't ask what a type is.

In set theory, when we say a statement like @${2 \in \mathbb{N}}, you're
making a statement about @${\mathbb{N}} --- we postulated the existence of
this inductive set with infinitely many elements, and however we chose to
represent @${2} was part of that inductively defined set.

In type theory, the definition of @${\mathbb{N}} looks a lot more like a
description: we add two rules to our theory,

@$${\ir{}{}{\Gamma \vdash \mathrm{zero} : \mathbb{N}} ~~
\ir{}{\Gamma \vdash m : \mathbb{N}}{\Gamma \vdash \mathrm{suc}\ m : \mathbb{N}}}

both of which describe what @italic{is} a natural number.

Don't worry about what these mean yet, but you can read it as "under any context,
zero is a natural number", and "if under some context, @${m} is a natural number,
then @${\mathrm{suc\ } m} is a natural number".

When we say that @${2 : \mathbb{N}}, then, we're saying that
@${\mathrm{suc\ (suc\ zero)} : \mathbb{N}}, which makes a statement about @${2}.

This is useful because in set theory, the intuition is you've constructed an
infinitely large set of things, and to check membership you just traverse that
infinite set. Computers are really bad at doing anything that's infinite.
(Obviously, there are ways of axiomatizing set theory that avoid this. The point
is that the philosophy of type theory is more compatible with computer-aided
proof.)

@; by: olive, 2022-12-28

@section{Classical propositional logic: semantics}

@bold{Definition:} Propositional logic is defined by the grammar:
@racketgrammar[#:literals (∧ ∨ → ¬)
prop-expr @; :=
  var
  (prop-expr ∧ prop-expr)
  (prop-expr ∨ prop-expr)
  (prop-expr → prop-expr)
  (¬ prop-expr)
]
where @tt{var} is some set of atomic symbols representing the variables.

Classical propositional logic deals with notions of "true" and "false", and the
semantics of it are truth-tables. As an example:
@tabular[
#:column-properties '(center center center)
#:row-properties '(bottom-border ())
(list (list @${A}          @${B}          @${A \to B})
      (list @${\mathsf{T}} @${\mathsf{T}} @${\mathsf{T}})
      (list @${\mathsf{T}} @${\mathsf{F}} @${\mathsf{F}})
      (list @${\mathsf{F}} @${\mathsf{T}} @${\mathsf{T}})
      (list @${\mathsf{F}} @${\mathsf{F}} @${\mathsf{T}}))
]
where each truth value has a different meaning for each propositional connective.
(We went over each connective, and worked some examples.)

@bold{Definition:} A @italic{valuation} is a function
@${v : \mathsf{Var} \to \{\mathsf{T}, \mathsf{F}\}} that assigns meaning to each
variable. Given a valuation @${v} and a @tt{prop-expr} @${e}, we write
@${\semantics{e}_v} to mean "the meaning of @${e} under the valuation @${v}".

We define the meaning of @${\semantics{e}_v} recursively for each connective:
@$${
\begin{align*}
  \semantics{X}_v &= v(X), \mathrm{when\ } x \in \mathsf{Var} \\
  \semantics{X \land Y}_v &= \semantics{X}_v \land \semantics{Y}_v \\
  \semantics{X \lor Y}_v &= \semantics{X}_v \lor \semantics{Y}_v \\
  \semantics{X \to Y}_v &= \semantics{X}_v \to \semantics{Y}_v \\
  \semantics{\neg X}_v &= \neg \semantics{X}_v
\end{align*}
}
where each connective on booleans is defined as usual.
