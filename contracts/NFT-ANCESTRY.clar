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
(define-constant err-invalid-relationship (err u109))
(define-constant err-relationship-exists (err u110))
(define-constant err-self-relationship (err u111))
(define-constant err-no-heritage-data (err u112))
(define-constant err-matching-disabled (err u113))
(define-constant err-match-not-found (err u114))
(define-constant err-already-matched (err u115))
(define-constant err-insufficient-compatibility (err u116))
(define-constant err-beneficiary-exists (err u117))
(define-constant err-not-beneficiary (err u118))
(define-constant err-vesting-active (err u119))
(define-constant err-no-beneficiary (err u120))
(define-constant err-already-endorsed (err u121))
(define-constant err-self-endorsement (err u122))
(define-constant err-no-endorsement (err u123))

(define-data-var last-token-id uint u0)
(define-data-var mint-enabled bool true)
(define-data-var verification-required bool false)
(define-data-var heritage-matching-enabled bool true)
(define-data-var min-compatibility-score uint u60)
(define-data-var next-match-id uint u1)

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
(define-map family-relationships {ancestor: uint, descendant: uint} (string-ascii 20))

(define-map heritage-patterns uint {
    cultural-keywords: (list 5 (string-ascii 30)),
    geographic-region: (string-ascii 100),
    time-era: (string-ascii 50),
    tradition-type: (string-ascii 50),
    language-family: (string-ascii 30),
    analyzed: bool
})

(define-map cultural-matches uint {
    token-a: uint,
    token-b: uint,
    compatibility-score: uint,
    match-factors: (list 3 (string-ascii 30)),
    discovered-at: uint,
    connection-confirmed: bool
})

(define-map heritage-connections {requester: uint, target: uint} {
    requested-at: uint,
    accepted: bool,
    match-id: uint
})

(define-map heritage-beneficiaries uint {
    beneficiary: principal,
    vesting-period: uint,
    designated-at: uint,
    can-claim: bool
})

(define-map token-endorsements {token-id: uint, endorser: principal} {
    endorsed-at: uint,
    endorsement-note: (string-ascii 100)
})

(define-map token-endorsement-counts uint uint)

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

(define-read-only (get-family-relationship (ancestor-id uint) (descendant-id uint))
    (map-get? family-relationships {ancestor: ancestor-id, descendant: descendant-id})
)

(define-read-only (get-ancestors (token-id uint))
    (ok "Use family-relationships map to find ancestors")
)

(define-read-only (get-descendants (token-id uint))
    (ok "Use family-relationships map to find descendants")
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

(define-public (link-family-members (ancestor-id uint) (descendant-id uint) (relationship (string-ascii 20)))
    (let 
        (
            (ancestor-owner (unwrap! (nft-get-owner? ancestry-nft ancestor-id) err-token-not-found))
            (descendant-owner (unwrap! (nft-get-owner? ancestry-nft descendant-id) err-token-not-found))
        )
        (asserts! (not (is-eq ancestor-id descendant-id)) err-self-relationship)
        (asserts! (or (is-eq tx-sender ancestor-owner) (is-eq tx-sender descendant-owner)) err-not-token-owner)
        (asserts! (is-none (map-get? family-relationships {ancestor: ancestor-id, descendant: descendant-id})) err-relationship-exists)
        (asserts! (or 
            (is-eq relationship "parent")
            (is-eq relationship "grandparent")
            (is-eq relationship "great-grandparent")
            (is-eq relationship "sibling")
            (is-eq relationship "cousin")
            (is-eq relationship "uncle")
            (is-eq relationship "aunt")
        ) err-invalid-relationship)
        (map-set family-relationships {ancestor: ancestor-id, descendant: descendant-id} relationship)
        (ok true)
    )
)

(define-public (remove-family-link (ancestor-id uint) (descendant-id uint))
    (let 
        (
            (ancestor-owner (unwrap! (nft-get-owner? ancestry-nft ancestor-id) err-token-not-found))
            (descendant-owner (unwrap! (nft-get-owner? ancestry-nft descendant-id) err-token-not-found))
        )
        (asserts! (or (is-eq tx-sender ancestor-owner) (is-eq tx-sender descendant-owner)) err-not-token-owner)
        (asserts! (is-some (map-get? family-relationships {ancestor: ancestor-id, descendant: descendant-id})) err-token-not-found)
        (map-delete family-relationships {ancestor: ancestor-id, descendant: descendant-id})
        (ok true)
    )
)

(define-public (analyze-heritage-pattern (token-id uint))
    (let (
        (story (unwrap! (map-get? heritage-stories token-id) err-story-not-found))
        (contribution (unwrap! (map-get? historical-contributions token-id) err-contribution-not-found))
        (owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found))
    )
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (var-get heritage-matching-enabled) err-matching-disabled)
        (let (
            (keywords (extract-cultural-keywords (get story story) (get cultural-significance story)))
            (region (normalize-geographic-region (get location story)))
            (era (normalize-time-period (get time-period story) (get historical-period contribution)))
            (tradition (categorize-tradition-type (get contribution-type contribution)))
            (language (derive-language-family region))
        )
            (map-set heritage-patterns token-id {
                cultural-keywords: keywords,
                geographic-region: region,
                time-era: era,
                tradition-type: tradition,
                language-family: language,
                analyzed: true
            })
            (ok true)
        )
    )
)

(define-public (discover-heritage-matches (token-id uint))
    (let (
        (pattern (unwrap! (map-get? heritage-patterns token-id) err-no-heritage-data))
        (owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found))
    )
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (get analyzed pattern) err-no-heritage-data)
        (asserts! (var-get heritage-matching-enabled) err-matching-disabled)
        (unwrap-panic (find-compatible-tokens token-id pattern))
        (ok true)
    )
)

(define-public (request-heritage-connection (requester-token uint) (target-token uint))
    (let (
        (requester-owner (unwrap! (nft-get-owner? ancestry-nft requester-token) err-token-not-found))
        (target-owner (unwrap! (nft-get-owner? ancestry-nft target-token) err-token-not-found))
        (existing-connection (map-get? heritage-connections {requester: requester-token, target: target-token}))
    )
        (asserts! (is-eq tx-sender requester-owner) err-not-token-owner)
        (asserts! (not (is-eq requester-token target-token)) err-self-relationship)
        (asserts! (is-none existing-connection) err-already-matched)
        (asserts! (var-get heritage-matching-enabled) err-matching-disabled)
        (let ((compatibility-score (calculate-compatibility-score requester-token target-token)))
            (asserts! (>= compatibility-score (var-get min-compatibility-score)) err-insufficient-compatibility)
            (map-set heritage-connections {requester: requester-token, target: target-token} {
                requested-at: stacks-block-height,
                accepted: false,
                match-id: u0
            })
            (ok compatibility-score)
        )
    )
)

(define-public (accept-heritage-connection (requester-token uint) (target-token uint))
    (let (
        (target-owner (unwrap! (nft-get-owner? ancestry-nft target-token) err-token-not-found))
        (connection (unwrap! (map-get? heritage-connections {requester: requester-token, target: target-token}) err-match-not-found))
        (match-id (var-get next-match-id))
    )
        (asserts! (is-eq tx-sender target-owner) err-not-token-owner)
        (asserts! (not (get accepted connection)) err-already-matched)
        (let (
            (compatibility-score (calculate-compatibility-score requester-token target-token))
            (match-factors (determine-match-factors requester-token target-token))
        )
            (map-set cultural-matches match-id {
                token-a: requester-token,
                token-b: target-token,
                compatibility-score: compatibility-score,
                match-factors: match-factors,
                discovered-at: stacks-block-height,
                connection-confirmed: true
            })
            (map-set heritage-connections {requester: requester-token, target: target-token} (merge connection {
                accepted: true,
                match-id: match-id
            }))
            (var-set next-match-id (+ match-id u1))
            (ok match-id)
        )
    )
)

(define-public (set-heritage-matching-enabled (enabled bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set heritage-matching-enabled enabled)
        (ok enabled)
    )
)

(define-public (set-min-compatibility-score (score uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= score u100) err-invalid-metadata)
        (var-set min-compatibility-score score)
        (ok score)
    )
)

(define-read-only (get-heritage-pattern (token-id uint))
    (map-get? heritage-patterns token-id)
)

(define-read-only (get-cultural-match (match-id uint))
    (map-get? cultural-matches match-id)
)

(define-read-only (get-heritage-connection (requester-token uint) (target-token uint))
    (map-get? heritage-connections {requester: requester-token, target: target-token})
)

(define-read-only (get-heritage-matching-stats)
    {
        total-matches: (- (var-get next-match-id) u1),
        matching-enabled: (var-get heritage-matching-enabled),
        min-compatibility: (var-get min-compatibility-score)
    }
)

(define-read-only (get-contract-info)
    {
        total-supply: (var-get last-token-id),
        mint-enabled: (var-get mint-enabled),
        verification-required: (var-get verification-required),
        heritage-matching-enabled: (var-get heritage-matching-enabled),
        min-compatibility-score: (var-get min-compatibility-score),
        owner: contract-owner
    }
)

(define-private (extract-cultural-keywords (story (string-ascii 500)) (significance (string-ascii 300)))
    (list "traditional" "cultural" "historic" "ancestral" "heritage")
)

(define-private (normalize-geographic-region (location (string-ascii 100)))
    (if (> (len location) u0) location "unknown")
)

(define-private (normalize-time-period (story-period (string-ascii 50)) (contrib-period (string-ascii 50)))
    (if (> (len story-period) u0) story-period contrib-period)
)

(define-private (categorize-tradition-type (contribution-type (string-ascii 50)))
    (if (> (len contribution-type) u0) contribution-type "general")
)

(define-private (derive-language-family (region (string-ascii 100)))
    (if (> (len region) u0) "regional" "unknown")
)

(define-private (find-compatible-tokens (token-id uint) (pattern {cultural-keywords: (list 5 (string-ascii 30)), geographic-region: (string-ascii 100), time-era: (string-ascii 50), tradition-type: (string-ascii 50), language-family: (string-ascii 30), analyzed: bool}))
    (ok true)
)

(define-private (calculate-compatibility-score (token-a uint) (token-b uint))
    (let (
        (pattern-a (map-get? heritage-patterns token-a))
        (pattern-b (map-get? heritage-patterns token-b))
    )
        (match pattern-a
            some-pattern-a (match pattern-b
                some-pattern-b (let (
                        (region-match (if (is-eq (get geographic-region some-pattern-a) (get geographic-region some-pattern-b)) u25 u0))
                        (era-match (if (is-eq (get time-era some-pattern-a) (get time-era some-pattern-b)) u25 u0))
                        (tradition-match (if (is-eq (get tradition-type some-pattern-a) (get tradition-type some-pattern-b)) u25 u0))
                        (language-match (if (is-eq (get language-family some-pattern-a) (get language-family some-pattern-b)) u25 u0))
                    )
                    (+ region-match era-match tradition-match language-match)
                )
                u0
            )
            u0
        )
    )
)

(define-private (determine-match-factors (token-a uint) (token-b uint))
    (let (
        (pattern-a (map-get? heritage-patterns token-a))
        (pattern-b (map-get? heritage-patterns token-b))
    )
        (list "geographic" "temporal" "cultural")
    )
)

(define-public (designate-beneficiary (token-id uint) (beneficiary principal) (vesting-blocks uint))
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (not (is-eq beneficiary owner)) err-invalid-metadata)
        (asserts! (is-none (map-get? heritage-beneficiaries token-id)) err-beneficiary-exists)
        (map-set heritage-beneficiaries token-id {
            beneficiary: beneficiary,
            vesting-period: vesting-blocks,
            designated-at: stacks-block-height,
            can-claim: false
        })
        (ok true)
    )
)

(define-public (update-beneficiary (token-id uint) (new-beneficiary principal) (vesting-blocks uint))
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (not (is-eq new-beneficiary owner)) err-invalid-metadata)
        (asserts! (is-some (map-get? heritage-beneficiaries token-id)) err-no-beneficiary)
        (map-set heritage-beneficiaries token-id {
            beneficiary: new-beneficiary,
            vesting-period: vesting-blocks,
            designated-at: stacks-block-height,
            can-claim: false
        })
        (ok true)
    )
)

(define-public (revoke-beneficiary (token-id uint))
    (let ((owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (is-some (map-get? heritage-beneficiaries token-id)) err-no-beneficiary)
        (map-delete heritage-beneficiaries token-id)
        (ok true)
    )
)

(define-public (activate-beneficiary-claim (token-id uint))
    (let (
        (owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found))
        (beneficiary-data (unwrap! (map-get? heritage-beneficiaries token-id) err-no-beneficiary))
    )
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (not (get can-claim beneficiary-data)) err-vesting-active)
        (map-set heritage-beneficiaries token-id (merge beneficiary-data {can-claim: true}))
        (ok true)
    )
)

(define-public (claim-heritage (token-id uint))
    (let (
        (owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found))
        (beneficiary-data (unwrap! (map-get? heritage-beneficiaries token-id) err-no-beneficiary))
        (vesting-complete (>= stacks-block-height (+ (get designated-at beneficiary-data) (get vesting-period beneficiary-data))))
    )
        (asserts! (is-eq tx-sender (get beneficiary beneficiary-data)) err-not-beneficiary)
        (asserts! (or (get can-claim beneficiary-data) vesting-complete) err-vesting-active)
        (try! (nft-transfer? ancestry-nft token-id owner tx-sender))
        (map-delete heritage-beneficiaries token-id)
        (ok true)
    )
)

(define-read-only (get-beneficiary-info (token-id uint))
    (map-get? heritage-beneficiaries token-id)
)

(define-read-only (can-claim-heritage (token-id uint) (claimer principal))
    (match (map-get? heritage-beneficiaries token-id)
        beneficiary-data (let (
            (is-beneficiary (is-eq claimer (get beneficiary beneficiary-data)))
            (vesting-complete (>= stacks-block-height (+ (get designated-at beneficiary-data) (get vesting-period beneficiary-data))))
            (manual-activation (get can-claim beneficiary-data))
        )
            (ok (and is-beneficiary (or manual-activation vesting-complete)))
        )
        (ok false)
    )
)

(define-public (endorse-heritage (token-id uint) (note (string-ascii 100)))
    (let (
        (owner (unwrap! (nft-get-owner? ancestry-nft token-id) err-token-not-found))
        (current-count (default-to u0 (map-get? token-endorsement-counts token-id)))
    )
        (asserts! (not (is-eq tx-sender owner)) err-self-endorsement)
        (asserts! (is-none (map-get? token-endorsements {token-id: token-id, endorser: tx-sender})) err-already-endorsed)
        (map-set token-endorsements {token-id: token-id, endorser: tx-sender} {
            endorsed-at: stacks-block-height,
            endorsement-note: note
        })
        (map-set token-endorsement-counts token-id (+ current-count u1))
        (ok (+ current-count u1))
    )
)

(define-public (revoke-endorsement (token-id uint))
    (let (
        (endorsement (unwrap! (map-get? token-endorsements {token-id: token-id, endorser: tx-sender}) err-no-endorsement))
        (current-count (default-to u1 (map-get? token-endorsement-counts token-id)))
    )
        (map-delete token-endorsements {token-id: token-id, endorser: tx-sender})
        (map-set token-endorsement-counts token-id (- current-count u1))
        (ok true)
    )
)

(define-read-only (get-endorsement-count (token-id uint))
    (default-to u0 (map-get? token-endorsement-counts token-id))
)

(define-read-only (get-endorsement (token-id uint) (endorser principal))
    (map-get? token-endorsements {token-id: token-id, endorser: endorser})
)

(define-read-only (has-endorsed (token-id uint) (endorser principal))
    (is-some (map-get? token-endorsements {token-id: token-id, endorser: endorser}))
)
