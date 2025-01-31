(use-trait ft-trait .safe-stream-token.safe-token)

;; Constants
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-amount (err u402))

;; Data structures
(define-map policies
  { policy-id: uint }
  {
    owner: principal,
    coverage-amount: uint,
    premium: uint,
    active: bool
  })

(define-map claims
  { claim-id: uint }
  {
    policy-id: uint,
    amount: uint,
    status: (string-ascii 10)
  })

;; Policy management
(define-public (create-policy (coverage uint) (premium uint))
  (let ((policy-id (get-next-policy-id)))
    (map-set policies
      { policy-id: policy-id }
      {
        owner: tx-sender,
        coverage-amount: coverage,
        premium: premium,
        active: true
      }
    )
    (ok policy-id)))

(define-public (file-claim (policy-id uint) (amount uint))
  (let ((claim-id (get-next-claim-id)))
    (asserts! (is-valid-policy policy-id) err-unauthorized)
    (map-set claims
      { claim-id: claim-id }
      {
        policy-id: policy-id,
        amount: amount,
        status: "PENDING"
      }
    )
    (ok claim-id)))
