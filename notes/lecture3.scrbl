#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt")
@(use-mathjax)
@(mathjax-preamble)

@; by: dave, 2023-01-02
@title[#:style (with-html5 manual-doc-style)]{Lecture 3: Intuitionistic propositional logic} 

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
