#lang racket
(provide (all-defined-out))

(module+ test
  (require rackunit)

  ; check-success intentionally removed
  (define-syntax-rule (check-error exp)
    (check-exn exn:fail? (thunk exp))))

;; throw-type-error! : String ... Anything -> Void
;; Throws an error with the given format string and arguments.
(define (throw-type-error! fmt . stuff)
  (error (apply format (string-append "ERROR: " fmt) stuff)))

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
;; - (syntax-+-elim Syntax Syntax Syntax)
;; - (syntax-⊥-elim Syntax)
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
(struct syntax-+-elim (scrut l-case r-case) #:transparent)
(struct syntax-⊥-elim (scrut) #:transparent)

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

;; pp : Syntax -> Sexp
;; Turns a piece of syntax into an S-expression.
;; Note the updating environment as we traverse.
(define (pp stx [env '()])
  (match stx
    [(syntax-local n) (list-ref env n)]
    [(syntax-lam var body)
     `(lambda (,var) ,(pp body (cons var env)))]
    [(syntax-app rator rand) `(,(pp rator env) ,(pp rand env))]
    [(syntax-hole c) (if c `(! ,(pp c env)) '_)]
    [(syntax-cons fst snd) `(cons ,(pp fst env) ,(pp snd env))]
    [(syntax-fst p) `(fst ,(pp p env))]
    [(syntax-snd p) `(snd ,(pp p env))]
    [(syntax-inl v) `(inl ,(pp v env))]
    [(syntax-inr v) `(inr ,(pp v env))]
    [(syntax-+-elim scrut l r) `(+-elim ,(pp scrut env) ,(pp l env) ,(pp r env))]
    [(syntax-⊥-elim scrut) `(⊥-elim ,(pp scrut env))]))

;; pp-type : Type -> Sexp
;; Turns a type into an S-expression.
(define (pp-type t)
  (match t
    [(type-base n) n]
    [(type-arrow dom rng) `(,(pp-type dom) → ,(pp-type rng))] 
    [(type-product a b) `(,(pp-type a) × ,(pp-type b))]
    [(type-sum a b) `(,(pp-type a) + ,(pp-type b))]
    [(type-bottom) '⊥]))

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

;; A Context is a [Assocof Symbol Type]

;; extend-context : Context Symbol Type -> Context
;; Adds a witness of the given type to the context.
(define (extend-context Γ name ty)
  (cons (cons name ty) Γ))

;; assert-type-equal! : Type Type -> Void
;; Asserts that two types are equal, and error if not.
(define (assert-type-equal! t1 t2)
  (unless (type=? t1 t2)
    ;; NOTE: "~a" is kind of like "%s" in C's printf.
    (throw-type-error! "non-equal types: ~a is not ~a" (pp-type t1) (pp-type t2))))

;; A ChkTactic is a (chk-tactic Symbol [Context Type -> Syntax])
;; A SynTactic is a (syn-tactic Symbol [Context -> [PairOf Type Syntax]])
(struct chk-tactic (name f)
  #:transparent
  #:property prop:procedure (struct-field-index f))
(struct syn-tactic (name f)
  #:transparent
  #:property prop:procedure (struct-field-index f))

;; run-chk : Type ChkTactic -> Void
;; Runs the given check tactic on the input type.
(define (run-chk goal tactic)
  (tactic '() goal))

;; run-syn : SynTactic -> Type
;; Runs the given synthesis tactic, producing the type it witnesses.
(define (run-syn tactic)
  (tactic '()))

;; chk : SynTactic -> ChkTactic
;; Implements the *conversion rule*,
;; which, given that t is a witness of the type P,
;; then t is also able to be checked as a witness of P.
(define/contract (chk tac)
  (syn-tactic? . -> . chk-tactic?)
  (chk-tactic
   'chk
   (λ (Γ goal)
     (match-define (cons tp tm) (tac Γ))
     (assert-type-equal! tp goal)
     tm)))

;; ann : ChkTactic Type -> SynTactic
;; Implements the *annotation rule*,
;; which, given that t can check as the type P,
;; allows t to be imbued with being a witness of P.
(define/contract (ann tac type)
  (chk-tactic? any/c . -> . syn-tactic?)
  (syn-tactic
   'imbue
   (λ (Γ)
     (define tm (tac Γ type))
     (cons type (syntax-ann tm type)))))

;; context-index-of : Context Symbol -> NaturalNumber
;; Returns the index of the symbol in the context.
(define (context-index-of Γ s)
  (match Γ
    ['() (error "not found")]
    [(cons (cons x _) rst)
     (cond [(eq? x s) 0]
           [else (add1 (context-index-of rst s))])]))

;; var : Symbol -> SynTactic
;; Implements the *variable rule*,
;; which, given a witness x of P in the context,
;; returns a tactic corresponding to x.
(define/contract (var s)
  (symbol? . -> . syn-tactic?)
  (syn-tactic
   'assumption
   (λ (Γ)
     (cons (dict-ref Γ s)
           (syntax-local (- (length Γ) (context-index-of Γ s) 1))))))

;; TODO: <tactics here>

;; A ConcreteSyntax is one of:
;; - (cs-var Symbol)
;; - (cs-lam Symbol ConcreteSyntax)
;; - (cs-app ConcreteSyntax ConcreteSyntax)
;; - (cs-ann ConcreteSyntax Type)
;; - (cs-hole [Maybe ConcreteSyntax])
;; - (cs-cons ConcreteSyntax ConcreteSyntax)
;; - (cs-fst ConcreteSyntax)
;; - (cs-snd ConcreteSyntax)
;; - (cs-inl ConcreteSyntax)
;; - (cs-inr ConcreteSyntax)
;; - (cs-+-elim ConcreteSyntax ConcreteSyntax ConcreteSyntax)
;; - (cs-⊥-elim ConcreteSyntax)
(struct cs-var (name) #:transparent)
(struct cs-lam (var body) #:transparent)
(struct cs-app (rator rand) #:transparent)
(struct cs-ann (tm tp) #:transparent)
(struct cs-hole (contents) #:transparent)
(struct cs-cons (fst snd) #:transparent)
(struct cs-fst (pair) #:transparent)
(struct cs-snd (pair) #:transparent)
(struct cs-inl (value) #:transparent)
(struct cs-inr (value) #:transparent)
(struct cs-+-elim (scrut l-case r-case) #:transparent)
(struct cs-⊥-elim (scrut) #:transparent)

;; TODO: <type-check, type-synth here>
