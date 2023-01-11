#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt"
          (for-label racket))
@(use-mathjax)
@(mathjax-preamble)

@; BY: NINE OR ROSE I DON'T REMEMBER, 2022-12-23
@title[#:style (with-html5 manual-doc-style)]{Propositional logic}

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
  \semantics{X}_v &= v(X), \mathrm{when\ } X \in \mathsf{Var} \\
  \semantics{X \land Y}_v &= \semantics{X}_v \land \semantics{Y}_v \\
  \semantics{X \lor Y}_v &= \semantics{X}_v \lor \semantics{Y}_v \\
  \semantics{X \to Y}_v &= \semantics{X}_v \to \semantics{Y}_v \\
  \semantics{\neg X}_v &= \neg \semantics{X}_v
\end{align*}
}
where each connective on booleans is defined as usual.

@bold{Definition:} A @tt{prop-expr} @${e} is a @italic{tautology} if
for all valuations @${v}, @${\semantics{e}_v = \mathsf{T}}.

@bold{Definition:} @${e} is @italic{satisfiable} if there is a valuation
@${v} such that @${\semantics{e}_v = \mathsf{T}}.

@bold{Definition:} @${e} is a @italic{contradiction} if there is no valuation
@${v} such that @${\semantics{e}_v = \mathsf{T}}, or in other words, if for
all valuations @${v}, @${\semantics{e}_v = \mathsf{F}}.

@section{Natural deduction}

In H241 (note: not C241), M384, et cetera, you would have been exposed to Fitch-style
natural deduction proofs.
We will not be doing those, instead opting for Gentzen-style natural deduction.

Natural deduction systems are comprised of @italic{inference rules}, which look
like this:
@$${\ir{}{\mathrm{assumption\ 1} ~~~ \mathrm{assumption\ 2} ~~~ \ldots ~~~ \mathrm{assumption\ } n}{\mathrm{consequent}}}
where everything above the line is something we already know, and the single thing below
the line is something we get as a result.

All of our connectives will have one of four (or five) types of associated rules:
@itemlist[
@item{@bold{Formation:} How to form a proposition syntactically. For example, given that @${A} is a
proposition and @${B} is a proposition, then @${A \to B} is a proposition. This effectively describes
the grammar of our logic.}
@item{@bold{Introduction:} How to construct a proof of a given proposition. For example,
given that we have a proof of @${A} and a proof of @${B}, then we can construct a proof of @${A \land B}.}
@item{@bold{Elimination:} How to get things from a proof of a given proposition. For example, given that
we have a proof of @${A \land B}, we can get a proof of @${B}.}
@item{@bold{Computation:} We will discuss this later in the course.}
@item{@bold{Uniqueness:} We will discuss this later in the course.}
]

@; 8y: Vera, 2022-12-31
@section{Classical propositional logic: proof system}

The formation rules are effectively the same as our grammar for @tt{prop-expr} in Exercise 1, and will
be ommitted for now, but, for example, they look like this:
@$${
\ir{(\land_{\mathrm{form}})}{A \mathrm{\ prop} ~~~ B \mathrm{\ prop}}{A \land B \mathrm{\ prop}} ~~~
\ir{(\bot_{\mathrm{form}})}{}{\bot \mathrm{\ prop}}
}

Implication is by far the most complex of our connectives, as with our current formulation of inference
rules, we have no good way of stating a Gentzen-style rule for @${\to_\mathrm{intro}}.
So, we will state elimination first:
@$${
\ir{(\to_{\mathrm{elim}})}{A \to B ~~~ A}{B}
}
This is often called "modus ponens", and it says that if @${A} implies @${B}, and also @${A}, then we have
@${B}.

Implication introduction requires more things in our proof system. Intuitively, @${A \to B} is true if,
when we assume @${A}, then we can derive @${B}. We don't have any notion of "assuming" in natural deduction
yet, so we need to add some extra things to our system.

Our introduction rule therefore looks like this:
@$${
\ir{(\to_{\mathrm{intro}})}
   {\begin{matrix}
      \ir{}{}{A} \\
      \vdots \\
      B
    \end{matrix}}
   {A \to B}
}
where the @${\vdots} represents a @italic{hypothetical derivation}. We will be revisiting this very soon.

This can be read as "we assume @${A}, and then derive @${B}" means that "if @${A}, then @${B}".

For conjunction, the inference rules are:
@$${
\ir{(\land_{\mathrm{intro}})}{A ~~~ B}{A \land B} ~~~
\ir{(\land_{\mathrm{elim}0})}{A \land B}{A} ~~~
\ir{(\land_{\mathrm{elim}1})}{A \land B}{B}
}
which are relatively straightforward to reason about: if both @${A} and @${B}, then @${A \land B},
and if @${A \land B}, then both @${A} and @${B}.

For disjunction, the inference rules are:
@$${
\ir{(\lor_{\mathrm{intro}0})}{A}{A \lor B} ~~~
\ir{(\lor_{\mathrm{intro}1})}{B}{A \lor B} ~~~
\ir{(\lor_{\mathrm{elim}})}{A \lor B ~~~ A \to C ~~~ B \to C}{C}
}
which require a bit more justification. If @${A}, then obviously @${A \lor B}, and the same for
@${B} then @${A \lor B}.

For negation, we @italic{define} @${\neg A} to be @${A \to \bot} (where that symbol is read as
"bottom"). This is the first serious departure from most expositions of propositional logic, so
make a note of it.

@${\bot} intentionally does not have an introduction rule, as it represents a contradiction.
Note that, with this definition, we can prove the @italic{law of non-contradiction}: that
@${\neg (A \land \neg A)}:
@$${
\ir{(\to_{\mathrm{elim}})}
   {\ir{(\land_{\mathrm{elim}1})}{A \land (A \to \bot)}{A \to \bot} ~~~
    \ir{(\land_{\mathrm{elim}0})}{A \land (A \to \bot)}{A}}
   {\bot}
}
(noting that I implicitly use implication introduction for simplicity.)

We have two rules for dealing with @${\bot}:
@$${
\ir{(\bot_{\mathrm{elim}})}{\bot}{A} ~~~
\ir{(\mathsf{DNE})}{\neg \neg A}{A}
}
referred to as the principle of explosion/ex falso, and double-negation elimination, respectively.
In essence, this states that if we can prove @${\bot}, we can prove anything. Double-negation
should seem intuitively sensible under the Boolean interpretation.

@section{Intuitionistic propositional logic}

We exposited the proof system for classical propositional logic, in which the truth
values correspond to the Boolean semantics, last lecture.

We will not be discussing the semantics of IPL: if you are interested, you should look
at Kripke models and realizability. (See LACI, 2.9)

The philosophical foundation for constructive mathematics, the primary topic of this course, is
that if something is true, you should be able to hand me a witness to that truth. This is based
in the notion of intuitionism, which says, in the loosest sense, that what is true is what you
can convince me is true.

If we downplay the notion of objective truth and whether or not our semantics can show if something
is a tautology, we can instead reason more about what proofs @italic{are}.

@section{The BHK interpretation}

The Brouwer-Heyting-Kolmogorov (BHK interpretation) is a way of assigning what a proof is --- as in,
the BHK interpretation of a formula is a kind of object you can hand to me to discern whether the
formula is true or not.

@bold{Definition:} We define the BHK interpretation of a formula inductively on connectives:
@itemlist[
@item{@${X \to Y} is interpreted as a function which, given a proof of @${X}, produces a proof of @${Y}.}
@item{@${X \land Y} is interpreted as a pair @${(a, b)}, where @${a} is a proof of @${X} and @${b} is a proof
of @${Y}.}
@item{@${X \lor Y} is either @${(0, a)} where @${a} is a proof of ${X}, or @${(1, b)} where @${b} is a proof
of @${Y}.}
@item{@${\neg X} is still defined as @${X \to \bot}.}
@item{@${\bot} has no proof.}
]

@; by: dare and maybe aradia: 2023-01-04
As an example, suppose that I wanted to prove @${(A \land \neg A) \to \bot}, otherwise known as the law of
non-contradiction. Then, I would want to construct a function from @${A \land \neg A} to @${\bot}.

@${A \land \neg A} is interpreted as a pair of proofs for @${A} and @${\neg A}, and @${\neg A} is interpreted
as a function @${A \to \bot}.

So, the function @${f((a, n)) = n(a)} is a witness to @${(A \land \neg A) \to \bot} under the BHK interpretation.

@section{Intuitionistic propositional logic: proof system}

In the last lecture, we wrote down a set of rules for classical propositional logic. The set of Gentzen-style
rules for IPL are exactly the same, except without the rule @${\mathsf{DNE}}.

Why is this the case? Note that in the BHK interpretation, there is not a clear way to construct a witness to
@${\neg \neg A \to A}. The only thing we have is a function, the only way we can eliminate a function is to
apply it to an argument, and we have no means to conjure an argument to our function out of thin air.

Tying this proof system to the BHK interpretation is the work of @italic{elaboration}, a later topic in this
course.
