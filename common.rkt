#lang at-exp racket/base
(require scribble-math/dollar
         gregor)
(provide (all-defined-out))

(define (mathjax-preamble)
  @$${\newcommand{\ir}[3]{\displaystyle\frac{#2}{#3}~{\textstyle #1}}
      \newcommand{\semantics}[1]{[\![ #1 ]\!]}
      \newcommand{\fst}[1]{\mathsf{fst\ } #1}
      \newcommand{\snd}[1]{\mathsf{snd\ } #1}})

(define first-tues (moment 2023 1 10))
(define first-thurs (moment 2023 1 12))

(define topic-dict
  `((,first-tues              . "Propositional logic")
    (,first-thurs             . "Tactics")
    (,(+weeks first-tues 1)   . "More tactics, Elaboration")
    (,(+weeks first-thurs 1)  . "Type theory")
    (,(+weeks first-tues 2)   . "Normalization by evaluation")
    (,(+weeks first-thurs 2)  . "NbE questions")
    (,(+weeks first-tues 3)   . "More NbE")
    (,(+weeks first-thurs 3)  . "Typed NbE")
    (,(+weeks first-tues 4)   . "A2 questions, A3 questions")
    (,(+weeks first-thurs 4)  . "More A3, Π types")
    (,(+weeks first-tues 5)   . "More Π, building Fin")
    (,(+weeks first-thurs 5)  . "Inductive types, recℕ")
    (,(+weeks first-tues 6)   . "How to do A4")
    (,(+weeks first-thurs 6)  . "Work on A4")
    (,(+weeks first-tues 7)   . "Σ types")
    (,(+weeks first-thurs 7)  . "Identity types, UIP, internalization")
    (,(+weeks first-tues 8)   . "More identity types")
    (,(+weeks first-thurs 8)  . "Tarski universes")
    (,(+weeks first-tues 10)  . "Part 2 logistics, introduction to Agda")
    (,(+weeks first-thurs 10) . "A5 work session")
    (,(+weeks first-tues 11)  . "HoTT: equivalences and bi-invertible maps")
    (,(+weeks first-thurs 11) . "Agda: identity, Σ, universes")
    (,(+weeks first-tues 12)  . "Agda: higher inductive types and Special Time™")
    (,(+weeks first-thurs 12) . "Agda: dependent eliminators for HITs (not present in class)")
    (,(+weeks first-tues 13)  . "HoTT: contractibility")
    (,(+weeks first-thurs 13) . "HoTT: propositions, sets, truncations")
    (,(+weeks first-tues 14)  . "Agda: π₁(S¹) ≃ ℤ")
    (,(+weeks first-thurs 14) . "HoTT: funext")
    (,(+weeks first-tues 15)  . "HoTT: univalence (not present in class)")
    (,(+weeks first-thurs 15) . "Agda: a little bit of cubical")))
