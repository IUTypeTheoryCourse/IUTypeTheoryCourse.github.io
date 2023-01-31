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
    (,(+weeks first-thurs 2)  . "Cancelled -- Ken fielded NbE questions")
    (,(+weeks first-tues 3)   . "More NbE")
    (,(+weeks first-thurs 3)  . "Typed NbE")
    (,(+weeks first-tues 4)   . "Dependent types: intro")
    (,(+weeks first-thurs 4)  . "Dependent types: implementation")
    (,(+weeks first-tues 5)   . "Dependent types: Σ, =")
    (,(+weeks first-thurs 5)  . "Inductive types")
    (,(+weeks first-tues 6)   . "Universes")))
