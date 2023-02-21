#lang scribble/manual
@(require scribble-math/dollar
          "../common.rkt"

          (for-label racket/base racket/match))
@(use-mathjax)
@(mathjax-preamble)

@; BY: KARKAT, 2023-02-20
@title[#:style (with-html5 manual-doc-style)]{Assignment 4: Dependent types}

This assignment will be assigned on February 21, 2023, and will be due on March 6, 2023. Corrections
will be accepted until March 20, 2023.

The purpose of this assignment is to extend your work on STLC, and add support for @${\Pi}-types, resulting in
a first brush at Martin-Löf type theory. This requires integrating the type checker from A2 with the normalizer
written in A3.

@italic{This assignment has many moving parts, and it will become easy to confuse variables.} Within the tactic
engine, I recommend naming all your tactic variables @tt{X-tac}, all your syntax variables @tt{X-stx}, and all
your value variables just @tt{X} (for some sensible @tt{X}).

The starter code is available @hyperlink["starter/mltt.rkt"]{here}.

@bold{Exercise 0:} Remove the code that normalizes your terms from @tt{run-chk} and @tt{run-syn}. You don't
need that anymore.

@bold{Exercise 1:} @italic{We're reviewing your application.} We no longer have a clear-cut function type
without closures inside of it. Consequently, preserving the type in @tt{do-app} will need to change.

Recall the (non-bidirectional) elimination rule for @${\Pi}:
@$${
\ir{(\Pi_{\mathrm{elim}})}
   {\Gamma \vdash f : \Pi_{(x : A)} B ~~~ \Gamma \vdash t : A}
   {\Gamma \vdash f\ t : B[x/t]}
}
We represent this substitution notion with a closure, and we apply the closure containing @${B} to @${t}.

Modify @tt{do-app} to handle this, updating the type you match on in the @tt{cut} case. Then, use
@tt{apply-closure} to get @${B}.

Finally, modify the @tt{reify} case that used to handle @tt{type-arrow}, and update it to use @tt{value-Π}.
Again, you need to use @tt{apply-closure} to get @${B} for your recursive call.

@bold{Exercise 2:} @italic{Arrows? What arrows?} With the removal of a basic arrow type, we also need to change
every time we used to call @tt{type-arrow} to @tt{value-Π}. But @tt{value-Π} takes a closure, which takes a
@tt{Syntax}, and we have a @tt{Value}!

To do this, we update our data definition of a closure:
@#reader scribble/comment-reader
(racketblock
  ;; A Closure is one of:
  ;; - (closure Syntax Environment)
  ;; - (h-closure [Value -> Value])
  (struct closure (term env) #:transparent)
  (struct h-closure (fn) #:transparent)
)
where we reuse Racket's lexical capture, and represent a closure directly as a function taking a value and
returning a value. This avoids having to call @tt{reify} and @tt{evaluate} just to construct types with known
values.

Update @tt{apply-closure} to handle this notion of closure. Everywhere where you used to use @tt{type-arrow},
update it to use @tt{value-Π} with this new notion of closure. Again, remember that
@${A \to B := \Pi_{(\_ : A)} B}.

@bold{Exercise 3:} @italic{Type-type-type.} Add a new case to @tt{reify}, matching on @tt{value-Type}.
Then, handle every constructor: @${\Pi}, @${\times}, @${+}, @${\bot}, @${\mathbb{N}}, @${\mathrm{Type}}, and cuts.

Reification for every case except @${\Pi} should be relatively straightforward.
You will need to use the provided helper function @tt{fresh-cut} to reify the closure representing @${B} in your
@${\Pi} case.

@bold{Sanity check:} At this point, you should be able to call @tt{normalize} on closed, well-typed @tt{Syntax}es.
You should not yet be able to type-check these terms, except by hand to generate test cases for @tt{normalize}
and the functions playing into it.

@; this exercise 8y Vera, 2023-02-21
@bold{Exercise 4:} @italic{Type tactics.} Everywhere you used to take a motive argument, you now need to take
a @tt{ChkTactic} that checks as @racket[(value-Type)]. Do this.

Whenever you need to turn that tactic's result from a @tt{Syntax} a @tt{Value} to return it from a
@tt{SyhTactic} or use it in another @tt{ChkTactic}, use @tt{eval-with-context}.

@bold{Exercise 5:} @italic{Baking a pi.} In class, we showed the well formedness rules for every type but
@${\Pi}.

The (bidirectional) well formedness rule for @${\Pi} is more complicated:
@$${
\ir{(\Pi_{\mathrm{wf}})}
   {\Gamma \vdash A \Leftarrow \mathrm{Type} ~~~ \Gamma, x : A \vdash B \Leftarrow \mathrm{Type}}
   {\Gamma \vdash \Pi_{(x : A)} B \Rightarrow \mathrm{Type}}
}

Design a function @tt{Π-form : Symbol ChkTactic ChkTactic -> SynTactic} that performs this typing
judgment. You will need to use @tt{eval-with-context} in order to get @${A} to add to the context.

@bold{Exercise 6:} @italic{Eating your pi.} In @tt{intro} and @tt{app}, we used to match on @tt{type-arrow}, and
we now need to match on @tt{value-Π}, which then gives us @${B} as a closure.

Per the last exercise, generate a fresh cut with @tt{fresh-with-context}, and use it to generate @${B}. You will
need to extend the context in @tt{intro}.

@; 8y: Vera, 2023-02-21
@bold{Sanity check:} You should now be able to type-check and normalize the identity function.

@bold{Exercise 7:} @italic{Trust the less natural natural recursion.} Your starter code contains the ability
to handle @tt{recℕ}. Recall the rules for @tt{indℕ}:

@$${
\ir{(\mathbb{N}_{\mathrm{ind}})}
   {\Gamma \vdash P : \mathbb{N} \to \mathrm{Type} ~~~
    \Gamma \vdash m : \mathbb{N} ~~~
    \Gamma \vdash base : P\ \mathrm{zero} ~~~
    \Gamma \vdash step : \Pi_{(k : \mathbb{N})} P\ k \to P\ (\mathrm{suc}\ k)}
   {\Gamma \vdash \mathrm{ind}_{\mathbb{N}}\ P\ m\ base\ step : P\ m}
}

Update your data definitions to rename @tt{recℕ} to @tt{indℕ}.

Extend the tactic for @tt{recℕ} to handle @tt{indℕ}, and rename it to @tt{indℕ}. You will have to use
the argument to your @tt{h-closure} to construct the type of @tt{step}.

Then, extend @tt{do-recℕ} to become @tt{do-indℕ}, noting that @tt{step} now takes two arguments.

The following exercises are not required for anyone.

@bold{Challenge exercise 1:} @italic{We're not providing much assistance, huh?} We have a type checker, but not
really a proof assistant. When we did A3, we ripped the holes out of our system.

Add holes back into your system, and integrate them with the normalizer.

@italic{Hint:} Modify the data definition for @tt{Head}.
