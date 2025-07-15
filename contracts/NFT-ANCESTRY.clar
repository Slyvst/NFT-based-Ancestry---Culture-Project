;; title: NFT-ANCESTRY
;; version: 1.0.0
;; summary: NFT-based Ancestry & Culture Project
;; description: Users mint NFTs linked to family heritage stories and historical contributions



(define-non-fungible-token ancestry-nft uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-token-not-found (err u103))
(define-constant err-invalid-metadata (err u104))
(define-constant err-story-not-found (err u105))
(define-constant err-contribution-not-found (err u106))
(define-constant err-not-approved (err u107))
(define-constant err-mint-disabled (err u108))

(define-data-var last-token-id uint u0)
(define-data-var mint-enabled bool true)
(define-data-var verification-required bool false)

(define-map token-uri uint (string-ascii 256))
(define-map heritage-stories uint {
    title: (string-ascii 100),
    story: (string-ascii 500),
    location: (string-ascii 100),
    time-period: (string-ascii 50),
    cultural-significance: (string-ascii 300),
    verified: bool
})

(define-map historical-contributions uint {
    contributor-name: (string-ascii 100),
    contribution-type: (string-ascii 50),
    description: (string-ascii 400),
    historical-period: (string-ascii 50),
    impact-level: (string-ascii 20),
    verified: bool
})

(define-map token-approvals uint principal)
(define-map operator-approvals {owner: principal, operator: principal} bool)
(define-map verifiers principal bool)

(define-public (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-public (get-token-uri (token-id uint))
    (ok (map-get? token-uri token-id))
)

(define-public (get-owner (token-id uint))
    (ok (nft-get-owner? ancestry-nft token-id))
)

(define-read-only (get-heritage-story (token-id uint))
    (map-get? heritage-stories token-id)
)

(define-read-only (get-historical-contribution (token-id uint))
    (map-get? historical-contributions token-id)
)

(define-read-only (is-mint-enabled)
    (var-get mint-enabled)
)

(define-read-only (is-verification-required)
    (var-get verification-required)
)

(define-read-only (is-verifier (user principal))
    (default-to false (map-get? verifiers user))
)

(define-public (mint-ancestry-nft 
    (to principal)
    (uri (string-ascii 256))
    (story-title (string-ascii 100))
    (story-content (string-ascii 500))
    (location (string-ascii 100))
    (time-period (string-ascii 50))
    (cultural-significance (string-ascii 300))
    (contributor-name (string-ascii 100))
    (contribution-type (string-ascii 50))
    (contribution-description (string-ascii 400))
    (historical-period (string-ascii 50))
    (impact-level (string-ascii 20))
)
    (let ((token-id (+ (var-get last-token-id) u1)))
        (asserts! (var-get mint-enabled) err-mint-disabled)
        (asserts! (> (len story-title) u0) err-invalid-metadata)
        (asserts! (> (len story-content) u0) err-invalid-metadata)
        (asserts! (> (len contributor-name) u0) err-invalid-metadata)
        
        (try! (nft-mint? ancestry-nft token-id to))
        (map-set token-uri token-id uri)
        (map-set heritage-stories token-id {
            title: story-title,
            story: story-content,
            location: location,
            time-period: time-period,
            cultural-significance: cultural-significance,
            verified: false
        })
        (map-set historical-contributions token-id {
            contributor-name: contributor-name,
            contribution-type: contribution-type,
            description: contribution-description,
            historical-period: historical-period,
            impact-level: impact-level,
            verified: false
        })
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (asserts! (is-eq sender (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)) err-not-token-owner)
        (try! (nft-transfer? ancestry-nft token-id sender recipient))
        (ok true)
    )
)

(define-public (approve (token-id uint) (spender principal))
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (map-set token-approvals token-id spender)
        (ok true)
    )
)

(define-public (set-approved-for-all (operator principal) (approved bool))
    (begin
        (map-set operator-approvals {owner: tx-sender, operator: operator} approved)
        (ok true)
    )
)

(define-public (transfer-from (token-id uint) (sender principal) (recipient principal))
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq owner sender) err-not-token-owner)
        (asserts! (or 
            (is-eq tx-sender sender)
            (is-eq tx-sender (unwrap! (map-get? token-approvals token-id) err-not-approved))
            (default-to false (map-get? operator-approvals {owner: sender, operator: tx-sender}))
        ) err-not-approved)
        (try! (nft-transfer? ancestry-nft token-id sender recipient))
        (map-delete token-approvals token-id)
        (ok true)
    )
)

(define-public (verify-heritage-story (token-id uint))
    (let ((story (unwrap! (map-get? heritage-stories token-id) err-story-not-found)))
        (asserts! (is-verifier tx-sender) err-not-approved)
        (map-set heritage-stories token-id (merge story {verified: true}))
        (ok true)
    )
)

(define-public (verify-historical-contribution (token-id uint))
    (let ((contribution (unwrap! (map-get? historical-contributions token-id) err-contribution-not-found)))
        (asserts! (is-verifier tx-sender) err-not-approved)
        (map-set historical-contributions token-id (merge contribution {verified: true}))
        (ok true)
    )
)

(define-public (update-heritage-story 
    (token-id uint)
    (story-title (string-ascii 100))
    (story-content (string-ascii 500))
    (location (string-ascii 100))
    (time-period (string-ascii 50))
    (cultural-significance (string-ascii 300))
)
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (> (len story-title) u0) err-invalid-metadata)
        (asserts! (> (len story-content) u0) err-invalid-metadata)
        (map-set heritage-stories token-id {
            title: story-title,
            story: story-content,
            location: location,
            time-period: time-period,
            cultural-significance: cultural-significance,
            verified: false
        })
        (ok true)
    )
)

(define-public (update-historical-contribution
    (token-id uint)
    (contributor-name (string-ascii 100))
    (contribution-type (string-ascii 50))
    (description (string-ascii 400))
    (historical-period (string-ascii 50))
    (impact-level (string-ascii 20))
)
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (> (len contributor-name) u0) err-invalid-metadata)
        (map-set historical-contributions token-id {
            contributor-name: contributor-name,
            contribution-type: contribution-type,
            description: description,
            historical-period: historical-period,
            impact-level: impact-level,
            verified: false
        })
        (ok true)
    )
)

(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set verifiers verifier true)
        (ok true)
    )
)

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete verifiers verifier)
        (ok true)
    )
)

(define-public (set-mint-enabled (enabled bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set mint-enabled enabled)
        (ok true)
    )
)

(define-public (set-verification-required (required bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set verification-required required)
        (ok true)
    )
)

(define-public (get-approved (token-id uint))
    (ok (map-get? token-approvals token-id))
)

(define-public (is-approved-for-all (owner principal) (operator principal))
    (ok (default-to false (map-get? operator-approvals {owner: owner, operator: operator})))
)

(define-read-only (get-tokens-by-owner (owner principal))
    (ok "Use nft-get-owner to check individual token ownership")
)

(define-read-only (get-token-count)
    (var-get last-token-id)
)

(define-read-only (get-contract-info)
    {
        total-supply: (var-get last-token-id),
        mint-enabled: (var-get mint-enabled),
        verification-required: (var-get verification-required),
        owner: contract-owner
    }
)
