(use-trait ft-trait .safe-stream-token.safe-token)

;; Constants
(define-constant min-voting-period u144) ;; ~1 day in blocks
(define-constant approval-threshold u750000) ;; 75% in basis points

;; Governance
(define-map votes
  { proposal-id: uint, voter: principal }
  { amount: uint })

(define-map proposals
  { proposal-id: uint }
  {
    claim-id: uint,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint
  })

(define-public (create-proposal (claim-id uint))
  (let ((proposal-id (get-next-proposal-id)))
    (map-set proposals
      { proposal-id: proposal-id }
      {
        claim-id: claim-id,
        start-block: block-height,
        end-block: (+ block-height min-voting-period),
        votes-for: u0,
        votes-against: u0
      }
    )
    (ok proposal-id)))

(define-public (vote (proposal-id uint) (amount uint) (support bool))
  (let ((proposal (unwrap! (get-proposal proposal-id) err-not-found)))
    (asserts! (is-active-proposal proposal) err-inactive)
    (try! (stake-votes amount))
    (record-vote proposal-id amount support)
    (ok true)))
