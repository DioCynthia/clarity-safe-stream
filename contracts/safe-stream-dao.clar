(use-trait ft-trait .safe-stream-token.safe-token)

;; Constants
(define-constant min-voting-period u144) ;; ~1 day in blocks
(define-constant approval-threshold u750000) ;; 75% in basis points
(define-constant err-not-found (err u404))
(define-constant err-inactive (err u405))
(define-constant err-already-voted (err u406))

;; Governance
(define-map votes
  { proposal-id: uint, voter: principal }
  { amount: uint, support: bool })

(define-map proposals
  { proposal-id: uint }
  {
    claim-id: uint,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    executed: bool
  })

(define-data-var next-proposal-id uint u1)

(define-public (create-proposal (claim-id uint))
  (let ((proposal-id (var-get next-proposal-id)))
    (map-set proposals
      { proposal-id: proposal-id }
      {
        claim-id: claim-id,
        start-block: block-height,
        end-block: (+ block-height min-voting-period),
        votes-for: u0,
        votes-against: u0,
        executed: false
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (print {event: "proposal-created", proposal-id: proposal-id})
    (ok proposal-id)))

(define-public (vote (proposal-id uint) (amount uint) (support bool))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) err-not-found))
    (voter tx-sender)
  )
    (asserts! (is-active-proposal proposal) err-inactive)
    (asserts! (not (has-voted proposal-id voter)) err-already-voted)
    (try! (contract-call? .safe-stream-token transfer amount voter (as-contract tx-sender)))
    (map-set votes
      { proposal-id: proposal-id, voter: voter }
      { amount: amount, support: support }
    )
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if support (+ (get votes-for proposal) amount) (get votes-for proposal)),
        votes-against: (if support (get votes-against proposal) (+ (get votes-against proposal) amount))
      })
    )
    (print {event: "vote-cast", proposal-id: proposal-id, voter: voter})
    (ok true)))

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (get-proposal proposal-id) err-not-found)))
    (asserts! (is-approved proposal) err-unauthorized)
    (asserts! (not (get executed proposal)) err-already-executed)
    (try! (contract-call? .safe-stream-core execute-claim (get claim-id proposal)))
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { executed: true })
    )
    (print {event: "proposal-executed", proposal-id: proposal-id})
    (ok true)))

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals {proposal-id: proposal-id}))

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? votes {proposal-id: proposal-id, voter: voter})))

(define-read-only (is-active-proposal (proposal (optional {
  claim-id: uint,
  start-block: uint,
  end-block: uint,
  votes-for: uint,
  votes-against: uint,
  executed: bool
})))
  (match proposal
    p (and
      (>= block-height (get start-block p))
      (<= block-height (get end-block p))
      (not (get executed p))
    )
    false))

(define-read-only (is-approved (proposal {
  claim-id: uint,
  start-block: uint,
  end-block: uint,
  votes-for: uint,
  votes-against: uint,
  executed: bool
}))
  (let ((total-votes (+ (get votes-for proposal) (get votes-against proposal))))
    (and
      (> total-votes u0)
      (>= (* (get votes-for proposal) u1000000) (* total-votes approval-threshold))
    )))
