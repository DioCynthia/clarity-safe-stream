(use-trait ft-trait .safe-stream-token.safe-token)

;; Constants
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-amount (err u402))
(define-constant err-expired-policy (err u403))
(define-constant err-insufficient-premium (err u404))

;; Data structures
(define-map policies
  { policy-id: uint }
  {
    owner: principal,
    coverage-amount: uint,
    premium: uint,
    active: bool,
    expiration: uint,
    premium-paid: uint
  })

(define-map claims
  { claim-id: uint }
  {
    policy-id: uint,
    amount: uint,
    status: (string-ascii 10),
    timestamp: uint
  })

;; Events
(define-data-var next-policy-id uint u1)
(define-data-var next-claim-id uint u1)

(define-public (create-policy (coverage uint) (premium uint))
  (let ((policy-id (var-get next-policy-id)))
    (asserts! (> coverage u0) err-invalid-amount)
    (asserts! (> premium u0) err-invalid-amount)
    (map-set policies
      { policy-id: policy-id }
      {
        owner: tx-sender,
        coverage-amount: coverage,
        premium: premium,
        active: true,
        expiration: (+ block-height u52560), ;; ~1 year
        premium-paid: u0
      }
    )
    (var-set next-policy-id (+ policy-id u1))
    (print {event: "policy-created", policy-id: policy-id, owner: tx-sender})
    (ok policy-id)))

(define-public (pay-premium (policy-id uint) (amount uint))
  (let ((policy (unwrap! (get-policy policy-id) err-unauthorized)))
    (asserts! (is-eq tx-sender (get owner policy)) err-unauthorized)
    (try! (contract-call? .safe-stream-token transfer amount tx-sender (as-contract tx-sender)))
    (map-set policies
      { policy-id: policy-id }
      (merge policy { premium-paid: (+ (get premium-paid policy) amount) })
    )
    (print {event: "premium-paid", policy-id: policy-id, amount: amount})
    (ok true)))

(define-public (file-claim (policy-id uint) (amount uint))
  (let (
    (claim-id (var-get next-claim-id))
    (policy (unwrap! (get-policy policy-id) err-unauthorized))
  )
    (asserts! (is-valid-policy policy-id) err-unauthorized)
    (asserts! (<= amount (get coverage-amount policy)) err-invalid-amount)
    (map-set claims
      { claim-id: claim-id }
      {
        policy-id: policy-id,
        amount: amount,
        status: "PENDING",
        timestamp: block-height
      }
    )
    (var-set next-claim-id (+ claim-id u1))
    (print {event: "claim-filed", claim-id: claim-id, policy-id: policy-id})
    (ok claim-id)))

(define-read-only (get-policy (policy-id uint))
  (map-get? policies {policy-id: policy-id}))

(define-read-only (is-valid-policy (policy-id uint))
  (match (get-policy policy-id)
    policy (and 
      (get active policy)
      (>= (get expiration policy) block-height)
      (>= (get premium-paid policy) (get premium policy))
    )
    false))
