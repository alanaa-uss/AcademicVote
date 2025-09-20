
;; title: AcademicVote
;; version: 1.0
;; summary: Decentralized platform for university governance and student organization decisions
;; description: A smart contract for managing academic voting processes including proposals, voting, and governance

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-VOTING-CLOSED (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-INVALID-DURATION (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-PROPOSAL-ENDED (err u106))
(define-constant ERR-PROPOSAL-NOT-ENDED (err u107))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-VOTING-DURATION u144) ;; Minimum voting duration in blocks (~24 hours)
(define-constant MAX-VOTING-DURATION u1008) ;; Maximum voting duration in blocks (~1 week)
(define-constant VOTING-POWER-THRESHOLD u1) ;; Minimum voting power required

;; Data variables
(define-data-var proposal-counter uint u0)
(define-data-var contract-paused bool false)

;; Data maps
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 20),
    proposal-type: (string-ascii 30)
  }
)

(define-map user-votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voting-power: uint, block-height: uint }
)

(define-map user-voting-power
  { user: principal }
  { power: uint }
)

(define-map authorized-proposers
  { user: principal }
  { authorized: bool }
)

;; Public functions

;; Initialize user voting power (can be called by contract owner or self)
(define-public (set-voting-power (user principal) (power uint))
  (begin
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender user)) ERR-NOT-AUTHORIZED)
    (ok (map-set user-voting-power { user: user } { power: power }))
  )
)

;; Authorize a user to create proposals
(define-public (authorize-proposer (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-proposers { user: user } { authorized: true }))
  )
)

;; Revoke proposal authorization
(define-public (revoke-proposer (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-proposers { user: user } { authorized: false }))
  )
)

;; Create a new proposal
(define-public (create-proposal
  (title (string-ascii 100))
  (description (string-ascii 500))
  (duration uint)
  (proposal-type (string-ascii 30))
)
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (start-block block-height)
      (end-block (+ block-height duration))
      (is-authorized (default-to false (get authorized (map-get? authorized-proposers { user: tx-sender }))))
    )
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (or is-authorized (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= duration MIN-VOTING-DURATION) (<= duration MAX-VOTING-DURATION)) ERR-INVALID-DURATION)

    (map-set proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        proposer: tx-sender,
        start-block: start-block,
        end-block: end-block,
        votes-for: u0,
        votes-against: u0,
        status: "active",
        proposal-type: proposal-type
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Cast a vote on a proposal
(define-public (vote (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (voter-power (default-to u0 (get power (map-get? user-voting-power { user: tx-sender }))))
      (existing-vote (map-get? user-votes { proposal-id: proposal-id, voter: tx-sender }))
    )
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (>= voter-power VOTING-POWER-THRESHOLD) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-eq (get status proposal) "active") ERR-VOTING-CLOSED)
    (asserts! (<= block-height (get end-block proposal)) ERR-PROPOSAL-ENDED)
    (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)

    ;; Record the vote
    (map-set user-votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, voting-power: voter-power, block-height: block-height }
    )

    ;; Update proposal vote counts
    (if vote-for
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) voter-power) })
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) voter-power) })
      )
    )
    (ok true)
  )
)

;; Finalize a proposal (can be called by anyone after voting period ends)
(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
    )
    (asserts! (> block-height (get end-block proposal)) ERR-PROPOSAL-NOT-ENDED)
    (asserts! (is-eq (get status proposal) "active") ERR-VOTING-CLOSED)

    (let
      (
        (votes-for (get votes-for proposal))
        (votes-against (get votes-against proposal))
        (new-status (if (> votes-for votes-against) "passed" "rejected"))
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { status: new-status })
      )
      (ok new-status)
    )
  )
)

;; Emergency pause/unpause (owner only)
(define-public (set-contract-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-paused paused))
  )
)

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get user's vote on a proposal
(define-read-only (get-user-vote (proposal-id uint) (voter principal))
  (map-get? user-votes { proposal-id: proposal-id, voter: voter })
)

;; Get user's voting power
(define-read-only (get-voting-power (user principal))
  (default-to u0 (get power (map-get? user-voting-power { user: user })))
)

;; Check if user is authorized to create proposals
(define-read-only (is-authorized-proposer (user principal))
  (default-to false (get authorized (map-get? authorized-proposers { user: user })))
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

;; Check if contract is paused
(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

;; Get proposal voting results
(define-read-only (get-proposal-results (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (ok {
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total-votes: (+ (get votes-for proposal) (get votes-against proposal)),
      status: (get status proposal)
    })
    ERR-PROPOSAL-NOT-FOUND
  )
)

;; Check if proposal is active
(define-read-only (is-proposal-active (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (and
      (is-eq (get status proposal) "active")
      (<= block-height (get end-block proposal))
    )
    false
  )
)
