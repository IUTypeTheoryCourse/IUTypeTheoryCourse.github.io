#lang at-exp racket/base
(require scribble-math/dollar)
(provide (all-defined-out))

(define (mathjax-preamble)
  @$${\newcommand{\ir}[3]{\displaystyle\frac{#2}{#3}~{\textstyle #1}}
      \newcommand{\semantics}[1]{[\![ #1 ]\!]}})
