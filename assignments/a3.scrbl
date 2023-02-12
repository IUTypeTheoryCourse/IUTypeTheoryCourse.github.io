#lang scribble/manual
@(require scribble-math/dollar
          "../common.rkt"

          (for-label racket/base racket/match))
@(use-mathjax)
@(mathjax-preamble)

@; 8y: olive, 2023-02-06
@title[#:style (with-html5 manual-doc-style)]{Assignment 3: Normalization by evaluation}

This assignment will be assigned on February 7, 2023, and will be due on February @bold{17}, 2023.
Corrections will be accepted until @bold{March 3}, 2023.

The purpose of this assignment is to extend your work for A2, and normalize the core terms that
come out of your elaborating type checker. This change requires a lot of mechanical work, and also
requires computation and possibly uniqueness rules.

In lecture, we presented the following rules for function types:
@$${
\ir{(\to_\beta)}
   {\Gamma, x : A \vdash b : B ~~~ \Gamma \vdash a : A}
   {\Gamma \vdash (\lambda x. b)\ a = b[x/a] : B}
~~~
\ir{(\to_\eta)}
   {\Gamma \vdash f : A \to B}
   {\Gamma \vdash f = (\lambda x. f x) : A \to B}
}

In the rest of this, we will be extending our normalizer to handle computation and uniqueness rules
for each of our types in A2. We start with our A2 code, and add the normalizer in the starter code,
available @hyperlink["starter/nbe.rkt"]{here}.

@bold{Exercise 0:} @italic{Products (done in class).} We add a computation rule to our system for products,
but not a uniqueness rule. Note that we @italic{could} add a uniqueness rule, but we do not.

@$${
\ir{(\times_{\beta_1})}
   {\Gamma \vdash a : A ~~~ \Gamma \vdash b : B}
   {\Gamma \vdash \mathrm{fst}\ (\mathrm{cons}\ a\ b) = a : A}
~~~
\ir{(\times_{\beta_2})}
   {\Gamma \vdash a : A ~~~ \Gamma \vdash b : B}
   {\Gamma \vdash \mathrm{snd}\ (\mathrm{cons}\ a\ b) = b : B}
}

Extend @tt{evaluate} to produce the new @tt{value-cons} node. To do this, match on @tt{syntax-cons},
thereby producing a @tt{value-cons} node.

Then, to support @tt{syntax-fst} and @tt{syntax-snd}, design functions @tt{do-fst : Value -> Value}
and @tt{do-snd : Value -> Value} that account for all relevant @tt{Value}s (so, @tt{Cut}s and @tt{value-cons}).
When encountering a neutral, push @tt{value-fst} and @tt{value-snd} onto the spine.

Then, extend @tt{reify} to account for it as well, modifying @tt{reify-form} and @tt{reify}. Make sure to
preserve type information throughout your cuts.

@bold{Exercise 1:} @italic{Motives.} Note that our @tt{Syntax} and @tt{Value} data definitions have changed
slightly from those in class. In particular, @tt{syntax-+-elim} now has a @tt{motive} field, which is a
@italic{type}. It represents the type we are eliminating into: for example, if the result of @tt{syntax-+-elim}
is @${C} and you're eliminating an @${A + B}, then the motive argument is @${C} and the function types
would be @${A \to C} and @${B \to C}.

Don't change your @tt{ConcreteSyntax} data definition: instead, in the tactics handling @tt{+-elim} and
@tt{⊥-elim}, add the motive as an argument during elaboration. So, if the tactic returns a @${C}, put that
@${C} in the resultant syntax as well.

@bold{Exercise 2:} @italic{Sums.} Here's the computation rules (again, no uniqueness) for sums:

@$${
\ir{(+_{\beta_1})}
   {\Gamma \vdash f : A \to C ~~~ \Gamma \vdash g : B \to C ~~~ \Gamma \vdash a : A}
   {\Gamma \vdash \mathrm{+-elim}\ C\ (\mathrm{inl}\ a)\ f\ g = f\ a : C}
~~~
\ir{(+_{\beta_2})}
   {\Gamma \vdash f : A \to C ~~~ \Gamma \vdash g : B \to C ~~~ \Gamma \vdash b : B}
   {\Gamma \vdash \mathrm{+-elim}\ C\ (\mathrm{inr}\ b)\ f\ g = g\ b : C}
}

Again, extend @tt{evaluate} and @tt{reify} to handle @tt{syntax-inl} and @tt{syntax-inr}. Then, design a function
@tt{do-+-elim : Value Value Value -> Value} accounting for all relevant @tt{Value}s. When encountering a neutral,
push @tt{value-+-elim} onto the spine.

Note that @tt{value-+-elim} takes @italic{four} arguments: the types for @${f} and @${g} in the above rules,
and @${f}, @${g} themselves. This is because in @tt{reify-form}, we need to  have the types for @${f} and
@${g} to recursively call @tt{reify}, as we did for application.

@bold{Exercise 3:} @italic{Bottom.} We have no computation or uniqueness rule for bottom. However, it still
needs to be added to @tt{evaluate} and @tt{reify}.

Design a function @tt{do-⊥-elim : Type Value -> Value} that performs bottom elimination. Note that since
we have no concrete values of type @${⊥}, all your scrutineés will be cuts.

Again, @tt{value-⊥-elim} needs a field for the type information --- this time, not because we need to recur
in @tt{reify-form}, but because our @tt{syntax-⊥-elim} @italic{also} needs that type information.

Then, extend @tt{evaluate} and @tt{reify}.

@bold{Exercise 4:} @italic{Tying the knot.} Modify @tt{run-chk} and @tt{run-syn} to produce a normal form of
the elaborated syntax, rather than the elaborated syntax.
