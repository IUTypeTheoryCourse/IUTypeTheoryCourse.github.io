#lang racket
(require racket/contract)

(module+ test
  (require rackunit)

  (define-syntax-rule (check-success exp)
    (check-not-exn (thunk exp)))
  (define-syntax-rule (check-error exp)
    (check-exn exn:fail? (thunk exp))))

;; throw-proof-error! : String ... Anything -> Void
;; Throws an error with the given format string and arguments.
(define (throw-proof-error! fmt . stuff)
  (error (apply format (string-append "ERROR: " fmt) stuff)))

;; A Proposition is one of:
;; - (prop-atomic Symbol)
;; - (prop-→ Proposition Proposition)
;; - (prop-∧ Proposition Proposition)
;; - (prop-∨ Proposition Proposition)
;; - (prop-⊥)
(struct prop-atomic (name) #:transparent)
(struct prop-→ (assumption consequent) #:transparent)
(struct prop-∧ (left right) #:transparent)
(struct prop-∨ (left right) #:transparent)
(struct prop-⊥ () #:transparent)

;; parse : Sexp -> Prop
;; Parses an infix S-expression into a proposition.
(define (parse s)
  (match s
    [`(,assumption → ,consequent) (prop-→ (parse assumption) (parse consequent))]
    [`(,l ∧ ,r) (prop-∧ (parse l) (parse r))]
    [`(,l ∨ ,r) (prop-∨ (parse l) (parse r))]
    [`(¬ ,v) (prop-→ (parse v) (prop-⊥))]
    ['⊥ (prop-⊥)]
    [(? symbol?) (prop-atomic s)]))

;; pp : Prop -> Sexp
;; Pretty-prints a proposition.
(define (pp prop)
  (match prop
    [(prop-atomic name) name]
    [(prop-→ assumption consequent) `(,(pp assumption) → ,(pp consequent))]
    [(prop-∧ l r) `(,(pp l) ∧ ,(pp r))]
    [(prop-∨ l r) `(,(pp l) ∨ ,(pp r))]
    [(prop-⊥) '⊥]))

;; prop=? : Prop Prop -> Boolean

;; TODO

;; assert-prop-equal! : Prop Prop -> Void
;; Asserts that two propositions are equal, and error if not.
(define (assert-prop-equal! t1 t2)
  (unless (prop=? t1 t2)
    ;; NOTE: "~a" is kind of like "%s" in C's printf.
    (throw-proof-error! "non-equal propositions: ~a is not ~a" (pp t1) (pp t2))))

;; A Context is a [Listof [Pairof Symbol Prop]]

;; extend-context : Context Symbol Prop -> Context
;; Adds a witness of the given proposition to the context.
(define (extend-context Γ name prop)
  (cons (cons name prop) Γ))

(module+ test
  (check-equal? (extend-context '() 'x (prop-⊥)) (list (cons 'x (prop-⊥))))
  (check-equal? (extend-context `((x . ,(prop-⊥))) 'y (prop-atomic 'A))
                (list (cons 'y (prop-atomic 'A)) (cons 'x (prop-⊥)))))

;; A ChkTactic is a (chk-tactic Symbol [Context Prop -> Void])
;; A SynTactic is a (syn-tactic Symbol [Context -> Prop])
(struct chk-tactic (name f)
  #:transparent
  #:property prop:procedure (struct-field-index f))
(struct syn-tactic (name f)
  #:transparent
  #:property prop:procedure (struct-field-index f))

;; run-chk : Prop ChkTactic -> Void
;; Runs the given check tactic on the input proposition.
(define (run-chk goal tactic)
  (tactic '() goal))

;; run-syn : SynTactic -> Prop
;; Runs the given synthesis tactic, producing the proposition it witnesses.
(define (run-syn tactic)
  (tactic '()))

;; chk : SynTactic -> ChkTactic
;; Implements the *conversion rule*,
;; which, given that t is a witness of the proposition P,
;; then t is also able to be checked as a witness of P.
(define/contract (chk tac)
  (syn-tactic? . -> . chk-tactic?)
  (chk-tactic
   'chk
   (λ (Γ goal)
     (define prop (tac Γ))
     (assert-prop-equal! prop goal))))

;; imbue : ChkTactic Prop -> SynTactic
;; Implements the *annotation rule*,
;; which, given that t can check as the proposition P,
;; allows t to be imbued with being a witness of P.
(define/contract (imbue tac prop)
  (chk-tactic? any/c . -> . syn-tactic?)
  (syn-tactic
   'imbue
   (λ (Γ)
     (tac Γ prop)
     prop)))

;; assumption : Symbol -> SynTactic
;; Implements the *variable rule*,
;; which, given a witness x of P in the context,
;; returns a tactic corresponding to x.
(define/contract (assumption s)
  (symbol? . -> . syn-tactic?)
  (syn-tactic
   'assumption
   (λ (Γ)
     (dict-ref Γ s))))

;; introduce : Symbol ChkTactic -> ChkTactic
;; Implements *→-introduction/direct proof*,
;; which, given that having a witness of P means that we can get a witness checking as Q,
;; gives us a witness checking as P → Q.

;; TODO

;; modus-ponens : SynTactic ChkTactic -> SynTactic
;; Implements *→-elimination/modus ponens/application*,
;; which, given a witness of P → Q and a witness checking as P,
;; gives us a witness of Q.

;; TODO

;; conjoin : ChkTactic ChkTactic -> ChkTactic
;; Implements ∧-introduction,
;; which, given a witness checking as P and a witness checking as Q,
;; gives us a witness checking as P ∧ Q.

;; TODO

;; fst : SynTactic -> SynTactic
;; Implements ∧-elimination (left),
;; which, given a witness of P ∧ Q,
;; gives us a witness of P.

;; TODO

;; snd : SynTactic -> SynTactic
;; Implements ∧-elimination (right),
;; which, given a witness of P ∧ Q,
;; gives us a witness of Q.

;; TODO

;; left-weaken : ChkTactic -> ChkTactic
;; Implements ∨-introduction (left)/weakening,
;; which, given a witness checking as P,
;; gives us a witness checking as P ∨ Q.

;; TODO

;; right-weaken : ChkTactic -> ChkTactic
;; Implements ∨-introduction (right)/weakening,
;; which, given a witness checking as Q,
;; gives us a witness checking as P ∨ Q.

;; TODO

;; cases : ChkTactic SynTactic SynTactic -> SynTactic
;; Implements ∨-elimination/proof by cases,
;; which, given a witness checking as P ∨ Q, a witness of P → R, and a witness of Q → R,
;; gives us a witness of R.

;; TODO

;; explode : SynTactic -> ChkTactic
;; Implements ex falso/the principle of explosion,
;; which, given a witness of ⊥ (false),
;; gives us a universal witness checking as anything.

;; TODO
