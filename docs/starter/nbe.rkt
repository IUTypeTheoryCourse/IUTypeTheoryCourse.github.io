#lang racket
(provide (all-defined-out))

(module+ test
  (require rackunit)

  ; check-success intentionally removed
  (define-syntax-rule (check-error exp)
    (check-exn exn:fail? (thunk exp))))

;; <A2 here: make sure that your Syntax data definition gets updated!>

;; A [Maybe X] is one of:
;; - X
;; - #f

;; A Syntax is one of:
;; - (syntax-local Number)
;; - (syntax-lam Symbol Syntax)
;; - (syntax-app Syntax Syntax)
;; - (syntax-hole [Maybe Syntax])
;; - (syntax-cons Syntax Syntax)
;; - (syntax-fst Syntax)
;; - (syntax-snd Syntax)
;; - (syntax-inl Syntax)
;; - (syntax-inr Syntax)
;; - (syntax-+-elim Type Syntax Syntax Syntax)
;; - (syntax-⊥-elim Type Syntax)
(struct syntax-local (n) #:transparent)
(struct syntax-lam (var body) #:transparent)
(struct syntax-app (rator rand) #:transparent)
(struct syntax-ann (tm tp) #:transparent)
(struct syntax-hole (contents) #:transparent)
(struct syntax-cons (fst snd) #:transparent)
(struct syntax-fst (pair) #:transparent)
(struct syntax-snd (pair) #:transparent)
(struct syntax-inl (value) #:transparent)
(struct syntax-inr (value) #:transparent)
(struct syntax-+-elim (motive scrut l-case r-case) #:transparent)
(struct syntax-⊥-elim (motive scrut) #:transparent)

;; A Type is one of:
;; - (type-base Symbol)
;; - (type-arrow Type Type)
;; - (type-product Type Type)
;; - (type-sum Type Type)
;; - (type-bottom)
(struct type-base (name) #:transparent)
(struct type-arrow (domain range) #:transparent)
(struct type-product (a b) #:transparent)
(struct type-sum (a b) #:transparent)
(struct type-bottom () #:transparent)

;; parse : Sexp -> Type
;; Parses an infix S-expression into a type.
(define (parse s)
  (match s
    [`(,assumption → ,consequent) (type-arrow (parse assumption) (parse consequent))]
    [`(,l × ,r) (type-product (parse l) (parse r))]
    [`(,l + ,r) (type-sum (parse l) (parse r))]
    [`(¬ ,v) (type-arrow (parse v) (type-bottom))]
    ['⊥ (type-bottom)]
    [(? symbol?) (type-base s)]))

;; A Closure is a (closure Syntax Environment)
(struct closure (term env) #:transparent)

;; A Environment is a [ListOf Value]

;; empty-env : -> Environment
(define (empty-env)
  '())

;; extend-env : Environment Value -> Environment
(define (extend-env env x)
  (cons x env))

;; apply-env : Environment Number -> Value
(define apply-env list-ref)

;; env-size : Environment -> Number
(define env-size length)

;; A Value is one of:
;; - Cut
;; - (value-lam Symbol Closure)
;; - (value-cons Value Value)
;; - (value-inl Value)
;; - (value-inr Value)
(struct value-lam (name clos) #:transparent)
(struct value-cons (first second) #:transparent)
(struct value-inl (left) #:transparent)
(struct value-inr (right) #:transparent)

;; A Cut is a (cut Type Head [ListOf Form])
(struct cut (tp head spine) #:transparent)

;; A Form is one of:
;; - (form-app Type Value)
;; - (form-fst)
;; - (form-snd)
;; - (form-+-elim Type Type Value Value)
;; - (form-⊥-elim Type)
(struct form-app (tp rand) #:transparent)
(struct form-fst () #:transparent)
(struct form-snd () #:transparent)
(struct form-+-elim (l-case-tp r-case-tp l-case r-case) #:transparent)
(struct form-⊥-elim (motive) #:transparent)

;; A Head is one of:
;; - (head-local Number)
;; *interpretation*: a head-local is a DeBruijn level that when quoted
;;                   gets read into a DeBruijn index to avoid having to
;;                   do shifting math in reify
(struct head-local (idx) #:transparent)

;; evaluate : Syntax Environment -> Value
;; Evaluates the expression to a normal form.
(define (evaluate exp env)
  (match exp
    [(syntax-ann tm _) (evaluate tm env)]
    [(syntax-local n) (apply-env env n)]
    [(syntax-lam value body) (value-lam value (closure body env))]
    [(syntax-app rator rand) (do-app (evaluate rator env)
                                     (evaluate rand env))]
    [(syntax-cons first second) (value-cons (evaluate first env)
                                            (evaluate second env))]
    [(syntax-fst p) (do-fst (evaluate p env))]
    [(syntax-snd p) (do-snd (evaluate p env))]))

(module+ test
  (check-equal?
   (evaluate (syntax-fst (syntax-cons (syntax-lam 'x (syntax-local 0))
                                      (syntax-lam 'x (syntax-lam 'y (syntax-local 0)))))
             (empty-env))
   (evaluate (syntax-lam 'x (syntax-local 0))
             (empty-env))) 

  (check-equal?
   (evaluate (syntax-app (syntax-lam 'x (syntax-lam 'y (syntax-local 1)))
                         (syntax-lam 'x (syntax-local 0)))
             (empty-env))
   (do-app (evaluate (syntax-lam 'x (syntax-lam 'y (syntax-local 1))) (empty-env))
           (evaluate (syntax-lam 'x (syntax-local 0)) (empty-env))))

  (check-equal?
   (evaluate (syntax-lam 'y (syntax-local 1))
             (extend-env (empty-env) (value-lam 'x (closure (syntax-local 0) (empty-env)))))
   (value-lam 'y (closure (syntax-local 1)
                          (extend-env (empty-env) (value-lam 'x (closure (syntax-local 0) (empty-env)))))))

  (check-equal?
   (evaluate (syntax-local 1)
             (extend-env
              (extend-env (empty-env)
                          (value-lam 'x (closure (syntax-local 0) (empty-env))))
              (cut (parse 'A) (head-local 0) '())))
   (value-lam 'x (closure (syntax-local 0) (empty-env))))

  ;; ---

  (check-equal?
   (evaluate (syntax-lam 'x (syntax-lam 'y (syntax-local 1))) (empty-env))
   (value-lam 'x (closure (syntax-lam 'y (syntax-local 1)) (empty-env))))
  (check-equal?
   (evaluate (syntax-lam 'x (syntax-local 0)) (empty-env))
   (value-lam 'x (closure (syntax-local 0) (empty-env)))))

;; do-app : Value Value -> Value
;; Applies the rator to the rand.
(define (do-app rator rand)
  (match rator
    [(value-lam _ closure) (apply-closure closure rand)]
    [(cut (type-arrow A B) head spine)
     (cut B head (cons (form-app A rand) spine))]))

(module+ test
  (check-equal?
   (do-app (value-lam 'x (closure (syntax-lam 'y (syntax-local 1)) (empty-env)))
           (value-lam 'x (closure (syntax-local 0) (empty-env))))
   (apply-closure (closure (syntax-lam 'y (syntax-local 1)) (empty-env))
                  (value-lam 'x (closure (syntax-local 0) (empty-env)))))

  (check-equal?
   (do-app
    (value-lam 'y (closure (syntax-local 1)
                           (extend-env (empty-env)
                                       (value-lam 'x (closure (syntax-local 0) (empty-env))))))
    (cut (parse 'A) (head-local 0) '()))
   (apply-closure (closure (syntax-local 1)
                           (extend-env (empty-env)
                                       (value-lam 'x (closure (syntax-local 0) (empty-env)))))
                  (cut (parse 'A) (head-local 0) '())))

  (check-equal?
   (do-app
    (value-lam 'x (closure (syntax-local 0) (empty-env)))
    (cut (parse 'B) (head-local 1) '()))
   (apply-closure (closure (syntax-local 0) (empty-env))
                  (cut (parse 'B) (head-local 1) '()))))

;; apply-closure : Closure Value -> Value
;; Applies the closure to the value.
(define (apply-closure clo rand)
  (match-define (closure tm env) clo)
  (evaluate tm (extend-env env rand)))

(module+ test
  (check-equal?
   (apply-closure (closure (syntax-lam 'y (syntax-local 1)) (empty-env))
                  (value-lam 'x (closure (syntax-local 0) (empty-env))))
   (evaluate (syntax-lam 'y (syntax-local 1))
             (extend-env (empty-env) (value-lam 'x (closure (syntax-local 0) (empty-env))))))

  (check-equal?
   (apply-closure (closure (syntax-local 1)
                           (extend-env (empty-env)
                                       (value-lam 'x (closure (syntax-local 0) (empty-env)))))
                  (cut (parse 'A) (head-local 0) '()))
   (evaluate (syntax-local 1)
             (extend-env
              (extend-env (empty-env)
                          (value-lam 'x (closure (syntax-local 0) (empty-env))))
              (cut (parse 'A) (head-local 0) '()))))

  (check-equal?
   (apply-closure (closure (syntax-local 0) (empty-env))
                  (cut (parse 'B) (head-local 1) '()))
   (cut (parse 'B) (head-local 1) '())))

;; do-fst : Value -> Value
;; Takes the first of the given value.
(define (do-fst p)
  (match p
    [(value-cons a b) a]
    [(cut (type-product A B) head spine)
     (cut A head (cons (form-fst) spine))]))

(module+ test
  (check-equal?
   (do-fst (value-cons (cut (parse 'A) (head-local 0) '())
                       (cut (parse 'A) (head-local 1) '())))
   (cut (parse 'A) (head-local 0) '()))
  (check-equal?
   (do-fst (cut (parse '(A × B)) (head-local 0) '()))
   (cut (parse 'A) (head-local 0) (cons (form-fst) '()))))

;; do-snd : Value -> Value
;; Takes the second of the given value.
(define (do-snd p)
  (match p
    [(value-cons a b) b]
    [(cut (type-product A B) head spine)
     (cut B head (cons (form-snd) spine))]))

;; reify : Number Value Type -> Syntax
;; Turns a value under the given environment size into a syntax.
(define (reify size val tp)
  (match tp    
    [(type-arrow A B)
     (syntax-lam
      (match val
        [(value-lam name _) name]
        [_ (gensym)])
      (reify (add1 size)
             (do-app val (cut A (head-local size) '()))
             B))]
    [(type-product A B)
     (match val
       [(value-cons fst snd) (syntax-cons (reify size fst A)
                                          (reify size snd B))]
       [(cut _ _ _) (reify-cut size val)])]  
    ;; only thing that can be a base type is a variable, represented by a cut
    ;; so don't even bother matching
    [(type-base _) (reify-cut size val)]))

;; reify-cut : Number Cut -> Syntax
;; Quotes a cut, by quoting its head and adding back all its eliminators.
(define (reify-cut size c)
  (match-define (cut _ head spine) c)
  (reify-spine size (reify-head size head) spine))

(module+ test
  (check-equal?
   (reify 0
          (value-cons (value-lam 'x (closure (syntax-local 0) (empty-env)))
                      (value-lam 'y (closure (syntax-local 0) (empty-env))))
          (parse '((A → A) × (B → B))))
   (syntax-cons (reify 0 (value-lam 'x (closure (syntax-local 0) (empty-env))) (parse '(A → A)))
                (reify 0 (value-lam 'y (closure (syntax-local 0) (empty-env))) (parse '(B → B)))))

  (check-equal?
   (reify 1
          (cut (parse '(A × B)) (head-local 0) '())
          (parse '(A × B)))
   (syntax-local 0))

  (check-equal?
   (reify
    0
    (value-lam 'y (closure (syntax-local 1)
                           (extend-env (empty-env)
                                       (value-lam 'x (closure (syntax-local 0) (empty-env))))))
    (parse '(A → (B → B))))
   (syntax-lam
    'y
    (reify 1
           (do-app
            (value-lam 'y (closure (syntax-local 1)
                                   (extend-env (empty-env)
                                               (value-lam 'x (closure (syntax-local 0) (empty-env))))))
            (cut (parse 'A) (head-local 0) '()))
           (parse '(B → B)))))

  (check-equal?
   (reify 1
          (value-lam 'x (closure (syntax-local 0) (empty-env)))
          (parse '(B → B)))
   (syntax-lam
    'x
    (reify 2
           (do-app
            (value-lam 'x (closure (syntax-local 0) (empty-env)))
            (cut (parse 'B) (head-local 1) '()))
           (parse 'B))))

  (check-equal?
   (reify 2
          (cut (parse 'B) (head-local 1) '())
          (parse 'B))
   (syntax-local 0)))

;; reify-head : Number Head -> Syntax
;; Turns a head into a syntax.
(define (reify-head size head)
  (match head
    [(head-local lvl) (syntax-local (- size lvl 1))]))

(module+ test
  (check-equal? (reify-head 2 (head-local 1))
                (syntax-local 0)))

;; reify-spine : Number Syntax [ListOf Form] -> Syntax
(define (reify-spine size exp spine)
  (match spine
    ['() exp]
    [(cons form rst)
     (reify-form size (reify-spine size exp rst) form)]))

(module+ test
  (check-equal?
   (reify-spine 2 (syntax-local 0) '())
   (syntax-local 0)))

;; reify-form : Number Syntax Form -> Syntax
(define (reify-form size exp form)
  (match form
    [(form-app A rand) (syntax-app exp (reify size rand A))]
    [(form-fst) (syntax-fst exp)]
    [(form-snd) (syntax-snd exp)]))

(module+ test
  (check-equal?
   (reify-form 1 (syntax-local 0) (form-fst))
   (syntax-fst (syntax-local 0))))

;; normalize : Syntax Type -> Syntax
;; Produces the normal form of the given syntax.
(define (normalize tm tp)
  (reify 0 (evaluate tm '()) tp))
