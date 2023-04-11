#lang scribble/manual
@(require scribble-math/dollar
          "../common.rkt"

          (for-label racket/base racket/match))
@(use-mathjax)
@(mathjax-preamble)

@title[#:style (with-html5 manual-doc-style)]{Assignment 5: Dependenter types}

This assignment will be assigned on April 11, 2023, and will be due at the latest
possible opportunity.

The purpose of this assignment is to extend your work on A4 to support sigma types
and identity.

This assignment is purposefully less detailed than A4. Remember the checklist for adding new things
to your type system:
@itemlist[
@item{Update @tt{evaluate} and @tt{reify} to handle your new data definitions.}
@item{Create a tactic combinator for each new form, where each premise (thing above the line) is a tactic argument.}
@item{Update @tt{type-check} and @tt{type-infer} to handle your new @tt{ConcreteSyntax} data definitions.}
@item{Test.}
]

The starter code is available on GitHub Classroom, with the link on Canvas.

@italic{This assignment is impossible without a completed A4.}

@bold{Exercise 1:} @italic{The cooler sum.} We have @tt{+-elim} in our old code.
Using the rules below, extend this implementation to implement @tt{ind+}.

This should be relatively routine at this point. Make sure to update every reference to @tt{+-elim}, and ensure
you're checking with the new dependent motive and type for @${f} and @${g}.

Note that the definition of @tt{form-ind+} has changed a bit. Namely, we save the type of the @tt{scrut} in the
@tt{scrut-tp} field, which provides enough information to reconstruct the type. (The same applies for the
@tt{scrut-tp} field of @tt{form-ind≡} later.)

@bold{Exercise 2:} @italic{Just what we needed: more Greek.} Using the rules below as a reference, modify
@tt{×-form} to become @tt{Σ-form}, and @tt{cons^}, @tt{fst}, and @tt{snd} to handle sigma types. This will look
very similar to the implementation of Π types.

@italic{Hint:} You will have to infer the type of @tt{scrut} before you can check the type of @tt{mot}.

@italic{Hint:} In @tt{snd}, you will need to get @tt{fst} of your pair. To do this, you'll make a call that
looks like @tt{(eval-with-context (syntax-fst ...) ...)}.

@bold{Exercise 3:} @italic{A missing rule.} Update @tt{reify} to handle eta for pairs, as given in the rule
@${\Sigma_\eta} below.

This will look similar to your implementation for eta for functions, in which you'll generate a cut of type
@tt{A}, apply it to @tt{B-clo}, and call @tt{do-fst} and @tt{do-snd}. There will be no matching on @tt{val}
after you determine that @tt{tp} is a dependent pair type.

@bold{Exercise 4:} @italic{Identity crisis.} Implement the rules below for identity types. Make sure to update
all moving components: so, normalization, tactics, etc.

@italic{Hint:} You will have to infer the type of @tt{scrut} before you can check the type of @tt{mot}.

@italic{Hint:} You will have an annoying nest of @tt{do-app}s in your @tt{ind≡} tactic combinator.

To help test, @italic{all} of the interesting things we've proven in class (up until HoTT) should now be
provable. Proving that @${m + 0 = m} and @${0 + m = m} are good tests --- you'll need to implement @tt{ap}.
I strongly recommend using the @tt{#lang} for testing, though it can be somewhat opaque.

@bold{Final type rule reference:}

Recall that @${\Leftarrow} represents a check tactic, and @${\Rightarrow} represents an infer tactic.

I like to remember this by thinking of how the arrow points in or out of the term: for @${\Rightarrow},
the type is given to us by the term which is why it points out, whereas with @${\Leftarrow} the type points
into the term, as we have to ensure the term has that type.

@italic{Bidirectional core:}
@$${
\ir{(\mathrm{Var})}
   {x : A \in \Gamma}
   {\Gamma \vdash x \Rightarrow A}
~~~
\ir{(\mathrm{Ann})}
   {\Gamma \vdash x \Leftarrow A}
   {\Gamma \vdash (x : A) \Rightarrow A}
~~~
\ir{(\mathrm{Conv})}
   {\Gamma \vdash x \Rightarrow A' ~~~ \Gamma \vdash A = A' : \mathrm{Type}}
   {\Gamma \vdash x \Leftarrow A}
}

@italic{Type-in-type (inconsistent):}
@$${
\ir{(\mathrm{Type}_{\mathrm{wf}})}
   {}
   {\Gamma \vdash \mathrm{Type} \Rightarrow \mathrm{Type}}
}

@italic{Pi types:}
@$${
\ir{(\Pi_{\mathrm{wf}})}
   {\Gamma \vdash A \Leftarrow \mathrm{Type} ~~~ \Gamma, x : A \vdash B \Leftarrow \mathrm{Type}}
   {\Gamma \vdash \Pi_{(x : A)} B \Rightarrow \mathrm{Type}}
}
@$${
\ir{(\Pi_{\mathrm{intro}})}
   {\Gamma, x : A \vdash b \Leftarrow B}
   {\Gamma \vdash \lambda x. b \Leftarrow \Pi_{(x : A)} B}
~~~
\ir{(\Pi_{\mathrm{elim}})}
   {\Gamma \vdash f \Rightarrow \Pi_{(x : A)} B ~~~ \Gamma \vdash t \Leftarrow A}
   {\Gamma \vdash f\ t \Rightarrow B[x \mapsto t]}
}
@$${
\ir{(\Pi_{\beta})}
   {\Gamma, x : A \vdash b : B ~~~ \Gamma \vdash a : A}
   {\Gamma \vdash (\lambda x. b)\ a = b[x \mapsto a] : B[x \mapsto a]}
~~~
\ir{(\Pi_{\eta})}
   {\Gamma \vdash f : \Pi_{(x : A)} B}
   {\Gamma \vdash f = (\lambda x. f\ x) : \Pi_{(x : A)} B}
}

Syntactic sugar: @${A \to B} is @${\Pi_{(\_ : A)} B}.

@italic{Sigma types:}
@$${
\ir{(\Sigma_{\mathrm{wf}})}
   {\Gamma \vdash A \Leftarrow \mathrm{Type} ~~~ \Gamma, x : A \vdash B \Leftarrow \mathrm{Type}}
   {\Gamma \vdash \Sigma_{(x : A)} B \Rightarrow \mathrm{Type}}
}
@$${
\ir{(\Sigma_{\mathrm{intro}})}
   {\Gamma \vdash a \Leftarrow A ~~~ \Gamma \vdash b \Leftarrow B[x \mapsto a]}
   {\Gamma \vdash (a, b) \Leftarrow \Sigma_{(x : A)} B}
}
@$${
\ir{(\Sigma_{\mathrm{elim0}})}
   {\Gamma \vdash p \Rightarrow \Sigma_{(x : A)} B}
   {\Gamma \vdash \mathrm{fst}\ p \Rightarrow A}
~~~
\ir{(\Sigma_{\mathrm{elim1}})}
   {\Gamma \vdash p \Rightarrow \Sigma_{(x : A)} B}
   {\Gamma \vdash \mathrm{snd}\ p \Rightarrow B[x \mapsto \mathrm{fst}\ p]}
}
@$${
\ir{(\Sigma_{\beta 0})}
   {\Gamma \vdash a : A ~~~ \Gamma \vdash b : B[x \mapsto a]}
   {\Gamma \vdash \mathrm{fst}\ (a, b) = a : A}
~~~
\ir{(\Sigma_{\beta 1})}
   {\Gamma \vdash a : A ~~~ \Gamma \vdash b : B[x \mapsto a]}
   {\Gamma \vdash \mathrm{snd}\ (a, b) = b : B[x \mapsto a]}
}
@$${
\ir{(\Sigma_\eta)}
   {\Gamma \vdash p : \Sigma_{(x : A)} B}
   {\Gamma \vdash p = (\mathrm{fst}\ p, \mathrm{snd}\ p) : \Sigma_{(x : A)} B}
}

Syntactic sugar: @${A \times B} is @${\Sigma_{(\_ : A)} B}.

@italic{Identity:}
@$${
\ir{(\equiv_{\mathrm{wf}})}
   {\Gamma \vdash A \Leftarrow \mathrm{Type} ~~~ \Gamma \vdash a \Leftarrow A ~~~ \Gamma \vdash a' \Leftarrow A}
   {\Gamma \vdash a \equiv_A a' \Rightarrow \mathrm{Type}}
~~~
\ir{(\equiv_{\mathrm{intro}})}
   {\Gamma \vdash a \Rightarrow A}
   {\Gamma \vdash \mathrm{refl}\ a \Rightarrow a \equiv_A a}
}
@$${
\ir{(\equiv_{\mathrm{ind}})}
   {\Gamma \vdash \mathrm{mot} \Leftarrow \Pi_{(x : A)} \Pi_{(y : A)} (x \equiv_A y) \to \mathrm{Type}
    ~~~
    \Gamma \vdash \mathrm{scrut} \Rightarrow x \equiv_A y
    ~~~
    \Gamma \vdash \mathrm{base} \Leftarrow \Pi_{(x : A)} \mathrm{mot}\ x\ x\ (\mathrm{refl}\ x)}
   {\Gamma \vdash \mathrm{ind}_\equiv\ \mathrm{mot}\ \mathrm{scrut}\ \mathrm{base} \Rightarrow \mathrm{mot}\ x\ y\ \mathrm{scrut}}
}
@$${
\ir{(\equiv_\beta)}
   {\Gamma \vdash \mathrm{mot} : \Pi_{(x : A)} \Pi_{(y : A)} (x \equiv_A y) \to \mathrm{Type}
    ~~~
    \Gamma \vdash \mathrm{base} : \Pi_{(x : A)} \mathrm{mot}\ x\ x\ (\mathrm{refl}\ x)
    ~~~
    \Gamma \vdash a : A}
   {\Gamma \vdash \mathrm{ind}_\equiv\ \mathrm{mot}\ (\mathrm{refl}\ a)\ \mathrm{base} = \mathrm{base}\ a : \mathrm{mot}\ a\ a\ (\mathrm{refl}\ a)}
}

@italic{Sum types:}
@$${
\ir{(+_\mathrm{wf})}
   {\Gamma \vdash A \Leftarrow \mathrm{Type} ~~~ \Gamma \vdash B \Leftarrow \mathrm{Type}}
   {\Gamma \vdash A + B \Rightarrow \mathrm{Type}}
}
@$${
\ir{(+_{\mathrm{intro}0})}
   {\Gamma \vdash a \Leftarrow A}
   {\Gamma \vdash \mathrm{inl}\ a \Leftarrow A+B}
~~~
\ir{(+_{\mathrm{intro}1})}
   {\Gamma \vdash b \Leftarrow B}
   {\Gamma \vdash \mathrm{inr}\ b \Leftarrow A+B}
}
@$${
\ir{(+_\mathrm{ind})}
   {\Gamma \vdash \mathrm{mot} \Leftarrow (A + B) \to \mathrm{Type}
    ~~~
    \Gamma \vdash \mathrm{scrut} \Rightarrow A + B
    ~~~
    \Gamma \vdash f \Leftarrow \Pi_{(a : A)} \mathrm{mot}\ (\mathrm{inl}\ a)
    ~~~
    \Gamma \vdash g \Leftarrow \Pi_{(b : B)} \mathrm{mot}\ (\mathrm{inr}\ b)}
   {\Gamma \vdash \mathrm{ind}_+\ \mathrm{mot}\ \mathrm{scrut}\ f\ g \Rightarrow \mathrm{mot}\ \mathrm{scrut}}
}
@$${
\ir{(+_{\beta 0})}
   {\Gamma \vdash \mathrm{mot} : (A + B) \to \mathrm{Type}
    ~~~
    \Gamma \vdash f : \Pi_{(a : A)} \mathrm{mot}\ (\mathrm{inl}\ a)
    ~~~
    \Gamma \vdash g : \Pi_{(b : B)} \mathrm{mot}\ (\mathrm{inr}\ b)
    ~~~
    \Gamma \vdash a : A}
   {\Gamma \vdash \mathrm{ind}_+\ \mathrm{mot}\ (\mathrm{inl}\ a)\ f\ g = f\ a : \mathrm{mot}\ (\mathrm{inl}\ a)}
}
@$${
\ir{(+_{\beta 1})}
   {\Gamma \vdash \mathrm{mot} : (A + B) \to \mathrm{Type}
    ~~~
    \Gamma \vdash f : \Pi_{(a : A)} \mathrm{mot}\ (\mathrm{inl}\ a)
    ~~~
    \Gamma \vdash g : \Pi_{(b : B)} \mathrm{mot}\ (\mathrm{inr}\ b)
    ~~~
    \Gamma \vdash b : B}
   {\Gamma \vdash \mathrm{ind}_+\ \mathrm{mot}\ (\mathrm{inr}\ b)\ f\ g = g\ b : \mathrm{mot}\ (\mathrm{inr}\ b)}
}

@italic{Bottom type:}
@$${
\ir{(\bot_{\mathrm{wf}})}
   {}
   {\bot \Rightarrow \mathrm{Type}}
~~~
\ir{(\bot_{\mathrm{elim}})}
   {\Gamma \vdash A \Leftarrow \mathrm{Type} ~~~ \Gamma \vdash b \Leftarrow \bot}
   {\Gamma \vdash \bot_{\mathrm{elim}}\ A\ b \Rightarrow A}
}

Syntactic sugar: @${\neg A} is @${A \to \bot}. (Not part of our concrete syntax.)

@italic{Naturals:}
@$${
\ir{(\mathbb{N}_{\mathrm{wf}})}
   {}
   {\Gamma \vdash \mathbb{N} \Rightarrow \mathrm{Type}}
~~~
\ir{(\mathbb{N}_{\mathrm{zero}})}
   {}
   {\Gamma \vdash \mathrm{zero} \Rightarrow \mathbb{N}}
~~~
\ir{(\mathbb{N}_{\mathrm{suc}})}
   {\Gamma \vdash n \Leftarrow \mathbb{N}}
   {\Gamma \vdash \mathrm{suc}\ n \Rightarrow \mathbb{N}}
}
@$${
\ir{(\mathbb{N}_{\mathrm{ind}})}
   {\Gamma \vdash \mathrm{mot} \Leftarrow \mathbb{N} \to \mathrm{Type} ~~~
    \Gamma \vdash \mathrm{scrut} \Leftarrow \mathbb{N} ~~~
    \Gamma \vdash \mathrm{base} \Leftarrow \mathrm{mot}\ \mathrm{zero} ~~~
    \Gamma \vdash \mathrm{step} \Leftarrow \Pi_{(k : \mathbb{N})} \mathrm{mot}\ k \to \mathrm{mot}\ (\mathrm{suc}\ k)}
   {\Gamma \vdash \mathrm{ind}_{\mathbb{N}}\ \mathrm{mot}\ \mathrm{scrut}\ \mathrm{base}\ \mathrm{step} \Rightarrow \mathrm{mot}\ \mathrm{scrut}}
}
@$${
\ir{(\mathbb{N}_{\beta\mathrm{zero}})}
   {\Gamma \vdash \mathrm{mot} : \mathbb{N} \to \mathrm{Type} ~~~
    \Gamma \vdash \mathrm{base} : \mathrm{mot}\ \mathrm{zero} ~~~
    \Gamma \vdash \mathrm{step} : \Pi_{(k : \mathbb{N})} \mathrm{mot}\ k \to \mathrm{mot}\ (\mathrm{suc}\ k)}
   {\Gamma \vdash \mathrm{ind}_{\mathbb{N}}\ \mathrm{mot}\ \mathrm{zero}\ \mathrm{base}\ \mathrm{step} = \mathrm{base} : \mathrm{mot}\ \mathrm{zero}}
}
@$${
\ir{(\mathbb{N}_{\beta\mathrm{suc}})}
   {\Gamma \vdash \mathrm{mot} : \mathbb{N} \to \mathrm{Type} ~~~
    \Gamma \vdash \mathrm{base} : \mathrm{mot}\ \mathrm{zero} ~~~
    \Gamma \vdash \mathrm{step} : \Pi_{(k : \mathbb{N})} \mathrm{mot}\ k \to \mathrm{mot}\ (\mathrm{suc}\ k) ~~~
    \Gamma \vdash m : \mathbb{N}}
   {\Gamma \vdash \mathrm{ind}_{\mathbb{N}}\ \mathrm{mot}\ (\mathrm{suc}\ m)\ \mathrm{base}\ \mathrm{step} = \mathrm{step}\ (\mathrm{ind}_{\mathbb{N}}\ \mathrm{mot}\ m\ \mathrm{base}\ \mathrm{step}) : \mathrm{mot}\ (\mathrm{suc}\ m)}
}

@italic{Not included:} formation rules (part of the grammar), rules for Tarski universes, "obvious" reductions (not β or η)
