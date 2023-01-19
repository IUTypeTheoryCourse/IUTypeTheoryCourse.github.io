#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt"
          (for-label racket rackunit))
@(use-mathjax)
@(mathjax-preamble)

@title[#:style (with-html5 manual-doc-style)]{The simply-typed lambda calculus} 

@section{The Curry-Howard correspondence}
@; by: roxy, 2023-01-18
Surprise! We're doing type theory in the type theory class. Big reveal.

@; by: ada, 2023-01-18
In particular, every instance of the word "proposition" in this course can be replaced with "type".
The following propositions can be interpreted as the following types in a conventional simply typed
lambda calculus:
@itemlist[
@item{Function types correspond to implications.}
@item{Product types/pair types correspond to logical and.}
@item{Sum types correspond to logical or.}
@item{The empty type corresponds to @${\bot}.}
]
In addition, our natural deduction proof system for IPL corresponds directly to the type system
for the simply typed lambda calculus.

Given the way that we represent BHK terms after elaboration, this should serve as no surprise.

In addition, this gives the somewhat surprising correspondence that an inhabited type corresponds to
an intuitionistic tautology.

However, in type theory, we traditionally have a term associated with a type. We define our
@italic{concrete syntax} to be this kind of term, with the traditional lambda calculus grammar:
@$${
e ::= x \mid \lambda x. e \mid e\ e \mid e : \tau
}
and we give grammar to our types as well:
@$${
\tau ::= A \mid \tau \to \tau
}

We also give Racket data definitions for these, calling our terms before elaboration @tt{ConcreteSyntax}
and after elaboration merely @tt{Syntax}:
@#reader scribble/comment-reader
(racketblock
  ;; A ConcreteSyntax is one of:
  ;; - (cs-var Symbol)
  ;; - (cs-lam Symbol ConcreteSyntax)
  ;; - (cs-app ConcreteSyntax ConcreteSyntax)
  ;; - (cs-ann ConcreteSyntax Type)
  (struct cs-var (name) #:transparent)
  (struct cs-lam (x body) #:transparent)
  (struct cs-app (rator rand) #:transparent)
  (struct cs-ann (tm tp) #:transparent)
)
noting that we have changed our original @tt{Prop} data definition to @tt{Type}. Note that also we have
the @tt{cs-ann} node in our concrete syntax, but not in our core terms!

@section{Type theory notation}
Before we move on to writing a type checker for STLC, we should actually state our type rules.

First, the most glaringly strange thing in our current IPL proof system is the notion of a hypothetical
derivation in our intro rule:
@$${
\ir{(\to_{\mathrm{intro}})}
   {\begin{matrix}
      \ir{}{}{A} \\
      \vdots \\
      B
    \end{matrix}}
   {A \to B}
}

The notion of hypothetical dervation is useful, but currently exists at a meta-theoretic level.
We now begin to label our antecedents with names, put them in our context, and then use the symbol @${\vdash}
to mean "proves".

In addition, we annotate each bit of our concrete syntax (corresponding to a non-elaborated BHK interpretation)
with its type.

As an immediate example, our implication introduction rule becomes:
@$${
\ir{(\to_\mathrm{intro})}
   {\Gamma, x : A \vdash y : B}
   {\Gamma \vdash \lambda x. y : A \to B}
}

Let's break this down. The line @${\Gamma, x : A \vdash y : B} reads "under a context @${\Gamma} where @${x} has
type @${A}, we can prove @${y} has type @${B}". Note the subtle distinction between @${:} on the left hand side
of @${\vdash} compared to the right.

We now need to rephrase our other rules in a similar fashion. Implication elimination is straightforward:
@$${
\ir{(\to_\mathrm{elim})}
   {\Gamma \vdash f : A \to B ~~~ \Gamma \vdash a : A}
   {\Gamma \vdash f\ a : B}
}

To finish up the proof system for the implicational fragment of IPL, we need to add one more rule with regards
to contexts that made no sense prior. In particular, we need a way to extract things from our context:
@$${
\ir{(\mathrm{Var})}
   {x : A \in \Gamma}
   {\Gamma \vdash x : A}
}
noting that @${\in} is effectively set-theoretic inclusion. Since contexts are finite, this is fine.

All of our other rules are more or less trivial to rephrase like this.

As an example, we are now free to actually write a proof tree to show that
@${\vdash \lambda x. \lambda y. x : A \to (B \to A)}:
@$${
\ir{(\to_\mathrm{intro})}
   {\ir{(\to_\mathrm{intro})}
       {\ir{(\mathrm{Var})}
           {x : A \in \Gamma, x : A, y : B} 
           {\Gamma, x : A, y : B \vdash x : A}}
       {\Gamma, x : A \vdash \lambda y. x : B \to A}}
   {\Gamma \vdash \lambda x. \lambda y. x : A \to (B \to A)}
}

We then also wrote a proof tree for @${\vdash \lambda a. \lambda f. f\ a : A \to ((A \to B) \to B)} in class.
(If you're reading this alone, do it yourself!)

@section{Bidirectional typing}

We've already been doing this for quite some time, but the time has come to formalize our tactics in good old
fashioned math notation.

Our @${\Gamma \vdash x : A} notation is relatively good, but does not give us a straightforward path to
implementation. Our check tactics, which correspond to the sequent @${\Gamma \vdash x : A} being valid,
are written as @${\Gamma \vdash x \Leftarrow A}. Our infer tactics, which correspond to the sequent giving
us what it proves, is written as @${\Gamma \vdash x \Rightarrow A}.

If we simply adapt our existing signatures to the three rules for the implicational fragment of STLC above,
we get the following rules:
@$${
\ir{(\to_\mathrm{intro})}
   {\Gamma, x : A \vdash y \Leftarrow B}
   {\Gamma \vdash \lambda x. y \Leftarrow A \to B}
}
@$${
\ir{(\to_\mathrm{elim})}
   {\Gamma \vdash f \Rightarrow A \to B ~~~ \Gamma \vdash a \Leftarrow A}
   {\Gamma \vdash f\ a \Rightarrow B}
}
@$${
\ir{(\mathrm{Var})}
   {x : A \in \Gamma}
   {\Gamma \vdash x \Rightarrow A}
}

This doesn't seem complete, and it's not. If we try to construct the proof tree for
@${\vdash \lambda a. \lambda f. f\ a : A \to ((A \to B) \to B)}, we can't, because we have no way to turn
inference into checking and vice versa. In our tactic system, we wrote @tt{chk} and @tt{imbue} for this purpose,
so let's turn them into rules.

@tt{chk} is relatively easy, and is called the conversion rule:
@$${
\ir{(\mathrm{Conv})}
   {\Gamma \vdash x \Rightarrow A' ~~~ A \equiv A'}
   {\Gamma \vdash x \Leftarrow A}
}
where @${A \equiv A'} means @tt{prop=?} for now. For brevity in examples, we may use this version of the rule:
@$${
\ir{(\mathrm{Conv})}
   {\Gamma \vdash x \Rightarrow A}
   {\Gamma \vdash x \Leftarrow A}
}
which means the same thing, except the definitional equality is implied by @${A} being the same thing on both
the top and the bottom.

Going the other way with @tt{imbue} is more complicated, and what our @tt{cs-ann} notation is for. This is yet
another override of what colon means.
@$${
\ir{(\mathrm{Ann})}
   {\Gamma \vdash x \Leftarrow A}
   {\Gamma \vdash (x : A) \Rightarrow A}
}

We now write the proof tree for 
@${\vdash \lambda a. \lambda f. f\ a \Leftarrow A \to ((A \to B) \to B)}. (Again, do it yourself!)

@section{Checking our concrete syntax}

Now that we have a notion of our concrete terms and how to check them, it's time to compile our terms to tactics.
We first start by renaming our tactics:
@itemlist[
@item{@tt{chk} stays the same.}
@item{@tt{imbue} becomes @tt{ann}.}
@item{@tt{introduce} stays the same.}
@item{@tt{modus-ponens} becomes @tt{app}.}
]

We now want to @italic{make} a type checker (or synthesizer) given a term. We do this with two functions:
@tt{type-check : ConcreteSyntax -> ChkTactic}, and @tt{type-synth : ConcreteSyntax -> SynTactic}, each of which
produces a tactic corresponding to the syntax we have.
