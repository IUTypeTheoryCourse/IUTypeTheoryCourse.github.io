#lang racket
(provide (all-defined-out))

(module+ test
  (require rackunit)

  ; check-success intentionally removed
  (define-syntax-rule (check-error exp)
    (check-exn exn:fail? (thunk exp))))

;;;; CORE TERMS

;; A Syntax is one of:
;; - (syntax-local Number)
;; - (syntax-ann Syntax Syntax)
;; 
;; - (syntax-Π Symbol Syntax Syntax)
;; - (syntax-lam Symbol Syntax)
;; - (syntax-app Syntax Syntax)
;;
;; - (syntax-× Syntax Syntax)
;; - (syntax-cons Syntax Syntax)
;; - (syntax-fst Syntax)
;; - (syntax-snd Syntax)
;; 
;; - (syntax-+ Syntax Syntax)
;; - (syntax-inl Syntax)
;; - (syntax-inr Syntax)
;; - (syntax-+-elim Syntax Syntax Syntax Syntax)
;;
;; - (syntax-⊥)
;; - (syntax-⊥-elim Syntax Syntax)
;;
;; - (syntax-ℕ)
;; - (syntax-zero)
;; - (syntax-suc Syntax)
;; - (syntax-recℕ Syntax Syntax Syntax Syntax)
;;
;; - (syntax-Type)
(struct syntax-local (n) #:transparent)
(struct syntax-ann (tm tp) #:transparent)

(struct syntax-Π (var dom rng) #:transparent
  #:methods gen:equal+hash
  [;; ignore the variable name in equal?
   (define (equal-proc pi1 pi2 rec-equal?)
     (and (rec-equal? (syntax-Π-dom pi1) (syntax-Π-dom pi2))
          (rec-equal? (syntax-Π-rng pi1) (syntax-Π-rng pi2))))
   (define (hash-proc pi rec)
     (+ (rec (syntax-Π-dom pi))
        (rec (syntax-Π-rng pi))))
   (define (hash2-proc pi rec)
     (+ (rec (syntax-Π-dom pi))
        (rec (syntax-Π-rng pi))))])
(struct syntax-lam (var body) #:transparent
  #:methods gen:equal+hash
  [;; ignore the variable name in equal?
   (define (equal-proc lam1 lam2 rec-equal?)
     (rec-equal? (syntax-lam-body lam1) (syntax-lam-body lam2)))
   (define (hash-proc lam rec)
     (rec (syntax-lam-body lam)))
   (define (hash2-proc lam rec)
     (rec (syntax-lam-body lam)))])
(struct syntax-app (rator rand) #:transparent)

(struct syntax-× (lhs rhs) #:transparent)
(struct syntax-cons (fst snd) #:transparent)
(struct syntax-fst (pair) #:transparent)
(struct syntax-snd (pair) #:transparent)

(struct syntax-+ (left right) #:transparent)
(struct syntax-inl (value) #:transparent)
(struct syntax-inr (value) #:transparent)
(struct syntax-+-elim (motive scrut l-case r-case) #:transparent)

(struct syntax-⊥ () #:transparent)
(struct syntax-⊥-elim (motive scrut) #:transparent)

(struct syntax-ℕ () #:transparent)
(struct syntax-zero () #:transparent)
(struct syntax-suc (n) #:transparent)
(struct syntax-recℕ (motive scrut base step) #:transparent)

(struct syntax-Type () #:transparent)

;; pp : Syntax -> Sexp
(define (pp stx [env '()])
  (match stx
    [(syntax-local n) (list-ref env n)]
    [(syntax-ann tm tp) `(: ,(pp tm env) ,(pp tp env))]

    [(syntax-Π var base fam)
     `(Π ([,var ,(pp base env)]) ,(pp fam (cons var env)))]
    [(syntax-lam var body)
     `(λ (,var) ,(pp body (cons var env)))]
    [(syntax-app rator rand) `(,(pp rator env) ,(pp rand env))]

    [(syntax-× fst snd)
     `(× ,(pp fst env) ,(pp snd env))]
    [(syntax-cons fst snd) `(cons ,(pp fst env) ,(pp snd env))]
    [(syntax-fst p) `(fst ,(pp p env))]
    [(syntax-snd p) `(snd ,(pp p env))]

    [(syntax-+ l r)
     `(+ ,(pp l env) ,(pp r env))]
    [(syntax-inl v) `(inl ,(pp v env))]
    [(syntax-inr v) `(inr ,(pp v env))]
    [(syntax-+-elim motive scrut l r) `(+-elim ,(pp motive env) ,(pp scrut env) ,(pp l env) ,(pp r env))]

    [(syntax-⊥) '⊥]
    [(syntax-⊥-elim motive scrut) `(⊥-elim ,(pp motive env) ,(pp scrut env))]

    [(syntax-ℕ) 'ℕ]
    [(syntax-zero) 0]
    [(syntax-suc n)
     (define res (pp n env))
     (cond [(number? res) (add1 res)]
           [else `(suc ,res)])]
    [(syntax-recℕ mot scrut base step)
     `(recℕ ,(pp mot env)
            ,(pp scrut env)
            ,(pp base env)
            ,(pp step env))]

    [(syntax-Type) 'Type]))

;;;; NORMALIZATION

;; A Value is one of:
;; - Cut
;;
;; - (value-Π Symbol Value Closure)
;; - (value-lam Symbol Closure)
;;
;; - (value-× Value Value)
;; - (value-cons Value Value)
;;
;; - (value-+ Value Value)
;; - (value-inl Value)
;; - (value-inr Value)
;;
;; - (value-⊥)
;;
;; - (value-ℕ)
;; - (value-zero)
;; - (value-suc Value)
;;
;; - (value-Type)
(struct value-Π (name base clo) #:transparent)
(struct value-lam (name clo) #:transparent)

(struct value-× (lhs rhs) #:transparent)
(struct value-cons (fst snd) #:transparent)

(struct value-+ (left right) #:transparent)
(struct value-inl (value) #:transparent)
(struct value-inr (value) #:transparent)

(struct value-⊥ () #:transparent)

(struct value-ℕ () #:transparent)
(struct value-zero () #:transparent)
(struct value-suc (n) #:transparent)

(struct value-Type () #:transparent)

;; A Cut is a (cut Value Head [ListOf Form])
(struct cut (tp head spine) #:transparent)

;; A Head is one of:
;; - (head-local PositiveInteger)
(struct head-local (lvl) #:transparent)

;; A Form is one of:
;; - (form-app Value Value)
;; - (form-fst)
;; - (form-snd)
;; - (form-+-elim Value Value Value Value Value)
;; - (form-⊥-elim Value)
;; - (form-recℕ Value Value Value)
(struct form-app (tp rand) #:transparent)
(struct form-fst () #:transparent)
(struct form-snd () #:transparent)
(struct form-+-elim (motive l-case-tp r-case-tp l-case r-case) #:transparent)
(struct form-⊥-elim (motive) #:transparent)
(struct form-recℕ (motive base step) #:transparent)

;; A Environment is a [ListOf Value]

;; A Closure is one of:
;; - (closure Syntax Environment)
;; - (h-closure [Value -> Value])
(struct closure (term env) #:transparent)
(struct h-closure (fn) #:transparent)

;; empty-env : -> Environment
;; Produces an empty environment.
(define (empty-env)
  '())

;; extend-env : Environment Value -> Environment
;; Adds a value to the environment.
(define (extend-env env x)
  (cons x env))

;; apply-env : Environment Number -> Value
;; Gets the nth element out of the environment.
(define (apply-env env n)
  (list-ref env n))

;; fresh-cut : Value Number -> Cut
;; Given a type and a number, generate a fresh cut.
(define (fresh-cut tp n)
  (cut tp (head-local n) '()))

;; throw-type-error! : -> Void
(define (throw-type-error! fmt . stuff)
  (error (apply format (string-append "TYPE ERROR: " fmt) stuff)))

;; do-recℕ : Value Value Value Value -> Value
;; Performs fold on the scrutineé.
(define (do-recℕ mot scrut base step)
  (match scrut
    [(value-zero) base]
    [(value-suc n) (do-app step
                           (do-recℕ mot n base step))]
    [(cut (value-ℕ) head spine)
     (cut mot head (cons (form-recℕ mot base step) spine))]))

;;;; TACTICS

;; A Context is a [Assocof Symbol Cut]
;; *Interpretation*: This is kind of an Environment, but it's also a context,
;;                   because cuts preserve type information.

;; extend-context : Context Symbol Value -> Context
;; Adds a witness of the given type to the context.
(define (extend-context Γ name c)
  (cons (cons name c) Γ))

;; fresh-with-context : Context Value -> Cut
;; Generates a fresh cut under the given context.
(define (fresh-with-context Γ tp)
  (fresh-cut tp (length Γ)))

;; eval-with-context : Value Context -> Syntax
;; Performs evaluation under the given context.
(define (eval-with-context val Γ)
  (evaluate val (map cdr Γ)))

;; reify-with-context : Context Value Value -> Syntax
;; Performs reification under the input context.
(define (reify-with-context Γ val tp)
  (reify (length Γ) val tp))

;; type=? : Value Value Context -> Boolean
;; Does conversion checking: is the type t1 compatible with t2?
(define (type=? t1 t2 ctx)
  (equal? (reify-with-context ctx t1 (value-Type))
          (reify-with-context ctx t2 (value-Type))))

;; assert-type-equal! : Type Type Context -> Void
;; Asserts that types are convertible.
(define (assert-type-equal! t1 t2 ctx)
  (unless (type=? t1 t2 ctx)
    (error (format "non-convertible types: ~a is not ~a"
                   (reify-with-context ctx t1 (value-Type))
                   (reify-with-context ctx t2 (value-Type))))))

;; context-index-of : Context Symbol -> NaturalNumber
;; Returns the index of the symbol in the context.
(define (context-index-of Γ s)
  (match Γ
    ['() (error "not found")]
    [(cons (cons x _) rst)
     (cond [(eq? x s) 0]
           [else (add1 (context-index-of rst s))])]))

;; A ChkTactic is a (chk-tactic Symbol [Context Value -> Syntax])
;; A SynTactic is a (syn-tactic Symbol [Context -> [PairOf Value Syntax]])
(struct chk-tactic (name f)
  #:transparent
  #:property prop:procedure (struct-field-index f))
(struct syn-tactic (name f)
  #:transparent
  #:property prop:procedure (struct-field-index f))

;; run-chk : Value ChkTactic -> Syntax
(define (run-chk goal tac)
  (tac '() goal))

;; run-syn : SynTactic -> [PairOf Type Syntax]
(define (run-syn tac)
  (tac '()))

;; chk : SynTactic -> ChkTactic
(define/contract (chk tac)
  (syn-tactic? . -> . chk-tactic?)
  (chk-tactic
   'chk
   (λ (Γ goal)
     (match-define (cons tp tm) (tac Γ))
     (assert-type-equal! tp goal Γ)
     tm)))

;; ann : ChkTactic ChkTactic -> SynTactic
(define/contract (ann tac tp-tac)
  (chk-tactic? any/c . -> . syn-tactic?)
  (syn-tactic
   'ann
   (λ (Γ)
     (define tp-stx (tp-tac Γ (value-Type)))
     (define tp (eval-with-context tp-stx Γ))
     (cons tp (tac Γ tp)))))

;; var : Symbol -> SynTactic
(define/contract (var s)
  (symbol? . -> . syn-tactic?)
  (syn-tactic
   'var
   (λ (Γ)
     (match-define (cut tp _ _) (dict-ref Γ s))
     (cons tp (syntax-local (context-index-of Γ s))))))

;; ×-form : ChkTactic ChkTactic -> SynTactic
(define/contract (×-form l-tac r-tac)
  (chk-tactic? chk-tactic? . -> . syn-tactic?)
  (syn-tactic
   '×-form
   (λ (Γ)
     (define l-stx (l-tac Γ (value-Type)))
     (define r-stx (r-tac Γ (value-Type)))
     (cons (value-Type) (syntax-× l-stx r-stx)))))

;; +-form : ChkTactic ChkTactic -> SynTactic
(define/contract (+-form l-tac r-tac)
  (chk-tactic? chk-tactic? . -> . syn-tactic?)
  (syn-tactic
   '+-form
   (λ (Γ)
     (define l-stx (l-tac Γ (value-Type)))
     (define r-stx (r-tac Γ (value-Type)))
     (cons (value-Type) (syntax-+ l-stx r-stx)))))

;; ⊥-form : SynTactic
(define ⊥-form
  (syn-tactic
   '⊥-form
   (λ (Γ)
     (cons (value-Type) (syntax-⊥)))))

;; ℕ-form : SynTactic
(define ℕ-form
  (syn-tactic
   'ℕ-form
   (λ (Γ)
     (cons (value-Type) (syntax-ℕ)))))

;; recℕ : ChkTactic ChkTactic ChkTactic ChkTactic -> SynTactic
;; Type-checks recursion on naturals.
(define/contract (recℕ mot-tac scrut-tac base-tac step-tac)
  (chk-tactic? chk-tactic? chk-tactic? chk-tactic? . -> . syn-tactic?)
  (syn-tactic
   'recℕ
   (λ (Γ)
     (define mot-stx (mot-tac Γ (value-Type)))
     (define mot (eval-with-context mot-stx Γ))
     (define scrut-stx (scrut-tac Γ (value-ℕ)))
     (define base-stx (base-tac Γ mot))
     (define step-stx (step-tac Γ (value-Π '_ mot (h-closure (λ (_) mot)))))
     (cons mot
           (syntax-recℕ mot scrut-stx base-stx step-stx)))))

;;;: TYPE-CHECK/TYPE-INFER

;; A ConcreteSyntax is one of:
;; - (cs-var Symbol)
;; - (cs-ann ConcreteSyntax ConcreteSyntax)
;;
;; - (cs-Π Symbol ConcreteSyntax ConcreteSyntax)
;; - (cs-→ ConcreteSyntax ConcreteSyntax)
;; - (cs-lam [ListOf Symbol] ConcreteSyntax)
;; - (cs-app ConcreteSyntax [ListOf ConcreteSyntax])
;;
;; - (cs-× ConcreteSyntax ConcreteSyntax)
;; - (cs-cons ConcreteSyntax ConcreteSyntax)
;; - (cs-fst ConcreteSyntax)
;; - (cs-snd ConcreteSyntax)
;;
;; - (cs-+ ConcreteSyntax ConcreteSyntax)
;; - (cs-inl ConcreteSyntax)
;; - (cs-inr ConcreteSyntax)
;; - (cs-+-elim ConcreteSyntax ConcreteSyntax ConcreteSyntax)
;; 
;; - (cs-⊥)
;; - (cs-⊥-elim ConcreteSyntax)
;;
;; - (cs-zero)
;; - (cs-suc ConcreteSyntax)
;; - (cs-num NaturalNumber)
;; - (cs-recℕ ConcreteSyntax ConcreteSyntax ConcreteSyntax ConcreteSyntax)
;;
;; - (cs-Type)
(struct cs-var (name) #:transparent)
(struct cs-ann (tm tp) #:transparent)

(struct cs-Π (var dom rng) #:transparent)
(struct cs-→ (dom rng) #:transparent)
(struct cs-lam (vars body) #:transparent)
(struct cs-app (rator rands) #:transparent)

(struct cs-× (lhs rhs) #:transparent)
(struct cs-cons (fst snd) #:transparent)
(struct cs-fst (pair) #:transparent)
(struct cs-snd (pair) #:transparent)

(struct cs-+ (left right) #:transparent)
(struct cs-inl (value) #:transparent)
(struct cs-inr (value) #:transparent)
(struct cs-+-elim (mot scrut l-case r-case) #:transparent)

(struct cs-⊥ () #:transparent)
(struct cs-⊥-elim (mot scrut) #:transparent)

(struct cs-ℕ () #:transparent)
(struct cs-zero () #:transparent)
(struct cs-suc (n) #:transparent)
(struct cs-num (n) #:transparent)
(struct cs-recℕ (mot scrut base step) #:transparent)

(struct cs-Type () #:transparent)
