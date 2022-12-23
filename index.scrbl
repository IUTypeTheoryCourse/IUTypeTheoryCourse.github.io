#lang scribble/manual

@title[#:style '(toc)]{B629 Spring 2023 -- Proofs as Programs}
@author[(author+email "Hazel Levine" "hrlevi@iu.edu")]

@bold{The exact contents of this entire course, and webpage, are currently subject to extreme change.}

The goal of this course is to serve as an introduction to two related, but notably distinct, topics:
@itemlist[
@item{@italic{Using} systems based on some type theory to prove theorems}
@item{@italic{Implementing} your own type theories}
]

Students will begin by implementing a proof checker for more traditional imperative propositional
logic style proofs, and then extend it into a type checker for the simply-typed lambda calculus. For
the first half of the course, students will extend this type checker incrementally with more features.

For the second half of this course, students will pivot to using a "production" type theory (Agda),
and prove various theorems both in and about homotopy type theory.

@(local-table-of-contents #:style 'immediate-only)

@include-section{syllabus.scrbl}
@include-section{lecture-notes.scrbl}
@include-section{assignments.scrbl}
@include-section{worksheets.scrbl}
