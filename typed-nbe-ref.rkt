#lang racket
(module+ test
  (require rackunit))

(require racket/trace)

;; A Type is one of:
;; - (type-base Symbol)
;; - (type-arrow Type Type)
(struct type-base (name) #:transparent)
(struct type-arrow (domain range) #:transparent)

;; A Syntax is one of:
;; A DeBruijn index:
;; - (syntax-local Number)
;; A lambda:
;; - (syntax-lam Symbol Syntax)
;; A let-binding:
;; - (syntax-let Symbol Syntax Syntax)
;; An application:
;; - (syntax-app Syntax Syntax)
;; An annotation:
;; - (syntax-ann Syntax Type)
(struct syntax-local (idx) #:transparent)
(struct syntax-lam (var body) #:transparent)
(struct syntax-let (var e body) #:transparent)
(struct syntax-app (rator rand) #:transparent)
(struct syntax-ann (tm tp) #:transparent)

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
;; - (value-ann Value Type)
(struct value-lam (name clos) #:transparent)
(struct value-ann (val tp) #:transparent)

;; A Cut is a (value-cut Type Head [ListOf Form])
(struct value-cut (tp head spine) #:transparent)

;; A Form is one of:
;; - (value-app Value)
(struct value-app (rand) #:transparent)

;; A Head is one of:
;; - (value-local Number)
;; - (value-let Number [PromiseOf Value])
(struct value-local (idx) #:transparent)
(struct value-let (idx promise) #:transparent)

;; evaluate : Syntax Environment -> Value
;; Evaluates the expression to a normal form.
(define (evaluate exp env)
  (match exp
    [(syntax-ann tm _) (evaluate tm env)]
    [(syntax-local n) (force (apply-env env n))]
    [(syntax-lam value body) (value-lam value (closure body env))]
    [(syntax-let _ _ _) (error "wait a min")]
    [(syntax-app rator rand) (do-app (evaluate rator env)
                                     (evaluate rand env))]))

#;(module+ test
  (check-equal?
   (evaluate (syntax-app (syntax-lam 'x (syntax-lam 'y (syntax-app (syntax-local 1) ; x
                                                                   (syntax-local 0) ; y
                                                                   )))
                         (syntax-lam 'x (syntax-local 0) ; x
                                     ))
             (empty-env))
   (value-lam 'y
              (closure (syntax-app (syntax-local 1) (syntax-local 0))
                       (list (delay/strict (value-lam 'x (closure (syntax-local 0) (empty-env)))))))))

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
     ;; can't be a lambda
     (match val
       [(value-cut _ head spine)
        (reify-spine size (reify-head size head) spine)])]
    [(type-arrow A B)
     (syntax-lam
      (match val
        [(value-lam var _) var]
        [_ (gensym)])
      (reify (add1 size)                          
             (do-app val (value-cut A (value-local size) '()))
             B))]))
(trace reify)

;; reify-head : Number Head -> Syntax
;; Turns a head into a syntax.
(define (reify-head size head)
  (match head
    [(value-local idx) (syntax-local (- size idx 1))]))

;; reify-spine : Number Syntax [ListOf Form] Type -> Syntax
(define (reify-spine size exp spine)
  (match spine
    ['() exp]
    [(cons form rst)
     (reify-spine size (reify-form size exp form) rst)]))

;; reify-form : Number Syntax Form -> Syntax
(define (reify-form size exp form)
  (match form
    [(value-app (value-ann rand tp)) (syntax-app exp (reify size rand tp))]))

;; normalize : Syntax Type -> Syntax
(define (normalize tm tp)
  (reify 0 (evaluate tm (empty-env)) tp))



#;(module+ test
  (check-equal?
   (reify 0
          (value-lam
           'y
           (closure (syntax-app (syntax-local 1) (syntax-local 0))
                    (list (delay/strict (value-lam 'x (closure (syntax-local 0) (empty-env)))))))
          (type-arrow (type-base 'A) (type-base 'A)))
   (syntax-lam 'y (syntax-local 0)))
  #;(check-equal?
   (reify 1 
          (apply-closure (closure
                          (syntax-app (syntax-local 1) (syntax-local 0))
                          (list (delay/strict (value-lam 'x (closure (syntax-local 0) (empty-env))))))
                         (value-cut (value-local 0) '())))
   (syntax-local 0)))


;; A [TB X] is a [Number -> X]

;; run-term-builder : {X} Environment [TB X] -> X
;; Produces the built core term, given an environment.
(define (run-term-builder env k)
  (k (env-size env)))

;; tb/var : Number -> [TB Syntax]
;; Given a DeBruijn index, produce a term builder giving
;; its DeBruijn level.
(define (tb/var idx)
  (λ (size)
    (syntax-local (- size idx 1))))

;; tb/bind-var : {X} [Number -> [TB X]] -> [TB X]
;; Takes the given term-builder-builder, and increment its environment size.
(define (tb/bind-var k)
  (λ (size)
    ((k size) (+ size 1))))

;; tb/scope : {X} [[TB Syntax] -> [TB X]] -> [TB X]
;; Scopes out the given variable, binding it for the term-builder-builder.
(define (tb/scope k)
  (tb/bind-var (λ (idx) (k (tb/var idx)))))

;; tb/let : Symbol [TB Syntax] [[TB Syntax] -> [TB Syntax]] -> [TB Syntax]
;; Build a let binding.
(define (tb/let var e body)
  (λ (size)
    (syntax-let var (e size) ((tb/scope body) size))))

;; tb/lam : Symbol [[TB Syntax] -> [TB Syntax]] -> [TB Syntax]
;; Build a lambda.
(define (tb/lam var body)
  (λ (size)
    (syntax-lam var ((tb/scope body) size))))

;; tb/app : [TB Syntax] -> [TB Syntax]
;; Build an application.
(define (tb/app rator rand)
  (λ (size)
    (syntax-app (rator size) (rand size))))


(define church-zero
  (tb/lam 'f
          (λ (f)
            (tb/lam 'x
                    (λ (x)
                      x)))))
(define church-add1
  (tb/lam 'n-1
          (λ (n-1)
            (tb/lam 'f
                    (λ (f)
                      (tb/lam 'x
                              (λ (x)
                                (tb/app f (tb/app (tb/app n-1 f) x)))))))))

(define church-+
  (tb/lam 'j
          (λ (j)
            (tb/lam 'k
                    (λ (k)
                      (tb/lam 'f
                              (λ (f)
                                (tb/lam 'x
                                        (λ (x)
                                          (tb/app (tb/app j f) (tb/app (tb/app k f) x)))))))))))

(define (to-church n)
  (cond [(zero? n) church-zero]
        [else (tb/app church-add1 (to-church (sub1 n)))]))

(normalize (run-term-builder (empty-env)
                             (tb/app (tb/app church-+ (to-church 2)) (to-church 3)))
           (type-arrow (type-arrow (type-base 'A) (type-base 'A)) ; f
                       (type-arrow (type-base 'A) ; x
                                   (type-base 'A))))
