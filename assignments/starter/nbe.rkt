#lang racket

;; A2 here

;; A Closure is a (closure Syntax Environment)
(struct closure (term env) #:transparent)

;; A Environment is a [ListOf [PromiseOf Value]]

;; empty-env : -> Environment
(define (empty-env)
  '())

;; extend-env : Environment [PromiseOf Value] -> Environment
(define (extend-env env x)
  (cons x env))

;; apply-env : Environment Number -> [PromiseOf Value]
(define apply-env list-ref)

;; env-size : Environment -> Number
(define env-size length)

;; A Value is one of:
;; - Cut
;; - (value-lam Symbol Closure)
;; - (value-cons Value Value)
;; - (value-inl Value)
;; - (value-inr Value)
;; - (value-ann Value Type)
(struct value-lam (name clos) #:transparent)
(struct value-cons (first second) #:transparent)
(struct value-inl (left) #:transparent)
(struct value-inr (right) #:transparent)
(struct value-ann (val tp) #:transparent)

;; A Cut is a (value-cut Type Head [ListOf Form])
(struct value-cut (tp head spine) #:transparent)

;; A Form is one of:
;; - (value-app Value)
;; - (value-fst)
;; - (value-snd)
;; - (value-+-elim Value Value)
;; - (value-⊥-elim)
(struct value-app (rand) #:transparent)
(struct value-fst () #:transparent)
(struct value-snd () #:transparent)
(struct value-+-elim (l-case r-case) #:transparent)
(struct value-⊥-elim () #:transparent)

;; A Head is one of:
;; - (value-local Number)
;; *interpretation*: a value-local is a DeBruijn level that when quoted
;;                   gets read into a DeBruijn index to avoid having to
;;                   do shifting math in reify
(struct value-local (idx) #:transparent)

;; evaluate : Syntax Environment -> Value
;; Evaluates the expression to a normal form.
(define (evaluate exp env)
  (match exp
    [(syntax-ann tm _) (evaluate tm env)]
    [(syntax-local n) (force (apply-env env n))]
    [(syntax-lam value body) (value-lam value (closure body env))]
    [(syntax-app rator rand) (do-app (evaluate rator env)
                                     (evaluate rand env))]))

;; do-app : Value Value -> Value
;; Applies the rator to the rand.
(define (do-app rator rand)
  (match rator
    [(value-lam _ closure) (apply-closure closure rand)]
    [(value-cut (type-arrow A B) head spine)
     (value-cut B head (cons (value-app (value-ann rand A)) spine))]))

;; apply-closure : Closure Value -> Value
;; Applies the closure to the value.
(define (apply-closure clo rand)
  (match-define (closure tm env) clo)
  (evaluate tm (extend-env env (delay/strict rand))))

;; reify : Number Value Type -> Syntax
;; Turns a value under the given environment size into a syntax.
(define (reify size val tp)
  (match tp
    [(type-base _)
     (match val
       [(value-cut _ head spine)
        (reify-spine size (reify-head size head) spine)])]
    [(type-arrow A B)
     (syntax-lam
      (match val
        [(value-lam name _) name]
        [_ (gensym)])
      (reify (add1 size)
             (do-app val (value-cut A (value-local size) '()))
             B))]))

;; reify-head : Number Head -> Syntax
;; Turns a head into a syntax.
(define (reify-head size head)
  (match head
    [(value-local lvl) (syntax-local (- size lvl 1))]))

;; reify-spine : Number Syntax [ListOf Form] -> Syntax
(define (reify-spine size exp spine)
  (match spine
    ['() exp]
    [(cons form rst)
     (reify-spine size (reify-form size exp form) rst)]))

;; reify-form : Number Syntax Form -> Syntax
(define (reify-form size exp form)
  (match form
    [(value-app (value-ann rand A)) (syntax-app exp (reify size rand A))]))

;; normalize : Syntax Type -> Syntax
;; Produces the normal form of the given syntax.
(define (normalize tm tp)
  (reify 0 (evaluate tm '()) tp))
