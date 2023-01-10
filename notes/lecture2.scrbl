#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt")
@(use-mathjax)
@(mathjax-preamble)

@; by: olive, 2022-12-29
@title[#:style (with-html5 manual-doc-style)]{Lecture 2: More propositional logic}

@section{Natural deduction}

In H241 (note: not C241), M384, et cetera, you would have been exposed to Fitch-style
natural deduction proofs that look kind of like this:

@; TODO: that

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
should seem intuitively sensible under the Boolean interpretation we discussed last lecture.
