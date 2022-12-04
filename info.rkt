#lang info

(define deps '("base"))
(define build-deps '("racket-doc"
                     "scribble-lib"))
(define scribblings '(("index.scrbl" (multi-page no-search))))
(define pkg-desc "The course website for CSCI-B 629.")
(define pkg-authors '(hrlevi))
