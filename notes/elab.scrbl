#lang scribble/manual

@(require scribble-math/dollar
          "../common.rkt"
          (for-label racket))
@(use-mathjax)
@(mathjax-preamble)

@title[#:style (with-html5 manual-doc-style)]{Elaboration} 

@section{What?}
@; by: Holly, 2023-01-11
In A1, we have a set of tactics that correspond to each individual rule of our IPL proof system. However, we are
still missing the crucial piece that ties our BHK interpretation to each rule. This piece is known as
@italic{elaboration}, and will be the start of our shift from propositions to types.
The goal of elaboration is for our tactics to produce not just a yes/no answer as to whether our proof is correct,
but a piece of syntax that, under the BHK interpretation, is an object you can hand me.

First, we are computer scientists, so we will be representing "functions" in the BHK interpretation using lambdas.
In other words, our old example of @${\neg (A \land \neg A)} being represented as @${f((a, n)) = n(a)} is now
represented by @${\lambda p. (\snd{p}) (\fst{p})}.

For the time being, we restrict our focus to the implicational fragment of our proof system. In A2, we will be
adding back our connectives.

@bold{Definition:} A @tt{Syntax} is defined as:
@racketgrammar[#:literals (syntax-local syntax-lam syntax-app symbol? natural?)
Syntax @; :=
  (syntax-local natural?)
  (syntax-lam symbol? Syntax)   
  (syntax-app Syntax Syntax)
]
and represented with the Racket definition:
@#reader scribble/comment-reader
(racketblock
  ;; A Syntax is one of:
  ;; A DeBruijn *level*:
  ;; - (syntax-local NaturalNumber)
  ;; A lambda:
  ;; - (syntax-lam Symbol Syntax)
  ;; An application:
  ;; - (syntax-app Syntax Syntax)
  (struct syntax-local (n) #:transparent)
  (struct syntax-lam (var body) #:transparent)
  (struct syntax-app (rator rand) #:transparent)
)

@section{DeBruijn levels}

Note that I mention DeBruijn levels here. Traditionally, we define a DeBruijn index, as in 311, as a way of
"pointing out" to our lambda. So, for example, the term
@$${\lambda x. \lambda y. z \mathrm{\ \ becomes\ \ } \lambda \lambda\ 1}
noting that we start indexing from zero, or
@$${\lambda z. (\lambda y. y\ (\lambda x. x)) (\lambda x. z\ x)
    \mathrm{\ \ becomes \ \ }
    \lambda\ (\lambda\ 1\ (\lambda\ 1)) (\lambda\ 2\ 1)}

@; 8y: olive, 2023-01-11
DeBruijn levels are the dual to these: instead of counting inside out, we count outside in. So:
@$${\lambda x. \lambda y. z \mathrm{\ \ becomes\ \ } \lambda \lambda\ 0}
@$${\lambda z. (\lambda y. y\ (\lambda x. x)) (\lambda x. z\ x)
    \mathrm{\ \ becomes \ \ }
    \lambda\ (\lambda\ 0\ (\lambda\ 2)) (\lambda\ 0\ 1)}

The motivation for this is that we can now not only unambiguously refer to variables as with DeBruijn indices,
but we do not need to keep track of the environment size at all: we can simply use @racket[list-ref] as our
environment application.

@; 8y: June Eg8ert, 2023-01-12
@section{Elaborating tactics}

Our last iteration of tactics has no clear way to return anything beyond a yes/no result. So, we need to update
our definition of a tactic.

@bold{Definition:} A @italic{check tactic} is now a function @tt{Context Prop -> Syntax} that, given a context
and a proposition, returns the BHK interpretation of the proof it represents if it can prove the proposition
under the context, and errors if it cannot.

@bold{Definition:} A @italic{infer tactic} is now a function @tt{Context -> [PairOf Prop Syntax]} that, given
a context, returns both the proposition that it proves and the BHK interpretation of the proof of that
proposition.
