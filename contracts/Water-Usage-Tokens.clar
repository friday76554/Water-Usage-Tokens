(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_TOKENS (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_INVALID_RECIPIENT (err u103))
(define-constant ERR_ALREADY_REGISTERED (err u104))
(define-constant ERR_NOT_REGISTERED (err u105))
(define-constant ERR_INVALID_USAGE_TYPE (err u106))
(define-constant ERR_READING_NOT_FOUND (err u107))
(define-constant ERR_INVALID_DATE (err u108))
(define-constant ERR_METER_NOT_FOUND (err u109))
(define-constant ERR_CHALLENGE_NOT_FOUND (err u110))
(define-constant ERR_CHALLENGE_ENDED (err u111))
(define-constant ERR_ALREADY_JOINED_CHALLENGE (err u112))
(define-constant ERR_NOT_JOINED_CHALLENGE (err u113))
(define-constant ERR_CHALLENGE_ACTIVE (err u114))
(define-constant ERR_INSUFFICIENT_ALLOWANCE (err u115))

(define-fungible-token water-usage-token)

(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var total-water-consumed uint u0)
(define-data-var token-price uint u1000000)

(define-map allowances
    {
        owner: principal,
        spender: principal,
    }
    { amount: uint }
)

(define-map reading-validators
    principal
    { enabled: bool }
)

(define-map water-meters
    principal
    {
        meter-id: (string-ascii 64),
        location: (string-utf8 256),
        installed-at: uint,
        is-active: bool,
        total-consumption: uint,
    }
)

(define-map water-readings
    uint
    {
        meter-owner: principal,
        meter-id: (string-ascii 64),
        reading-date: uint,
        consumption-amount: uint,
        reading-type: (string-ascii 32),
        validated: bool,
        validator: (optional principal),
    }
)

(define-map user-balances
    principal
    {
        total-tokens: uint,
        total-consumption: uint,
        registration-date: uint,
        tier-level: uint,
    }
)

(define-map consumption-rewards
    uint
    {
        tier: uint,
        min-consumption: uint,
        max-consumption: uint,
        reward-rate: uint,
    }
)

(define-map usage-penalties
    uint
    {
        penalty-type: (string-ascii 32),
        threshold: uint,
        penalty-rate: uint,
        description: (string-utf8 256),
    }
)

(define-map conservation-challenges
    uint
    {
        challenge-id: uint,
        title: (string-utf8 128),
        description: (string-utf8 256),
        start-block: uint,
        end-block: uint,
        target-reduction: uint,
        reward-pool: uint,
        participant-count: uint,
        is-active: bool,
        creator: principal,
    }
)

(define-map challenge-participants
    {
        challenge-id: uint,
        participant: principal,
    }
    {
        baseline-consumption: uint,
        current-consumption: uint,
        reduction-achieved: uint,
        joined-at: uint,
        reward-claimed: bool,
    }
)

(define-data-var next-reading-id uint u1)
(define-data-var contract-paused bool false)
(define-data-var next-challenge-id uint u1)

(define-read-only (get-name)
    (ok "Water Usage Token")
)

(define-read-only (get-symbol)
    (ok "WUT")
)

(define-read-only (get-decimals)
    (ok u6)
)

(define-read-only (get-balance (owner principal))
    (ok (ft-get-balance water-usage-token owner))
)

(define-read-only (get-allowance
        (owner principal)
        (spender principal)
    )
    (match (map-get? allowances {
        owner: owner,
        spender: spender,
    })
        data (ok (get amount data))
        (ok u0)
    )
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply water-usage-token))
)

(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

(define-read-only (get-water-meter (owner principal))
    (map-get? water-meters owner)
)

(define-read-only (get-water-reading (reading-id uint))
    (map-get? water-readings reading-id)
)

(define-read-only (get-user-balance-info (user principal))
    (map-get? user-balances user)
)

(define-read-only (get-consumption-reward (tier uint))
    (map-get? consumption-rewards tier)
)

(define-read-only (get-usage-penalty (penalty-id uint))
    (map-get? usage-penalties penalty-id)
)

(define-read-only (get-total-water-consumed)
    (var-get total-water-consumed)
)

(define-read-only (get-token-price)
    (var-get token-price)
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

(define-read-only (get-conservation-challenge (challenge-id uint))
    (map-get? conservation-challenges challenge-id)
)

(define-read-only (get-challenge-participant
        (challenge-id uint)
        (participant principal)
    )
    (map-get? challenge-participants {
        challenge-id: challenge-id,
        participant: participant,
    })
)

(define-read-only (get-active-challenges)
    (var-get next-challenge-id)
)

(define-read-only (calculate-tokens-for-consumption (consumption uint))
    (let ((base-rate u10))
        (ok (* consumption base-rate))
    )
)

(define-read-only (get-user-tier (user principal))
    (match (map-get? user-balances user)
        user-data (ok (get total-consumption user-data))
        (ok u0)
    )
)

(define-public (transfer
        (amount uint)
        (sender principal)
        (recipient principal)
        (memo (optional (buff 34)))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (not (is-eq sender recipient)) ERR_INVALID_RECIPIENT)
        (try! (ft-transfer? water-usage-token amount sender recipient))
        (print {
            action: "transfer",
            sender: sender,
            recipient: recipient,
            amount: amount,
        })
        (ok true)
    )
)

(define-public (approve
        (spender principal)
        (amount uint)
    )
    (let ((caller tx-sender))
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (not (is-eq caller spender)) ERR_INVALID_RECIPIENT)
            (map-set allowances {
                owner: caller,
                spender: spender,
            } { amount: amount }
            )
            (print {
                action: "approve",
                owner: caller,
                spender: spender,
                amount: amount,
            })
            (ok true)
        )
    )
)

(define-public (transfer-from
        (amount uint)
        (owner principal)
        (recipient principal)
        (memo (optional (buff 34)))
    )
    (let (
            (spender tx-sender)
            (allowed (default-to u0
                (get amount
                    (map-get? allowances {
                        owner: owner,
                        spender: spender,
                    })
                )))
        )
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (> amount u0) ERR_INVALID_AMOUNT)
            (asserts! (not (is-eq owner recipient)) ERR_INVALID_RECIPIENT)
            (asserts! (>= allowed amount) ERR_INSUFFICIENT_ALLOWANCE)
            (try! (ft-transfer? water-usage-token amount owner recipient))
            (map-set allowances {
                owner: owner,
                spender: spender,
            } { amount: (- allowed amount) }
            )
            (print {
                action: "transfer-from",
                spender: spender,
                owner: owner,
                recipient: recipient,
                amount: amount,
            })
            (ok true)
        )
    )
)

(define-public (register-water-meter
        (meter-id (string-ascii 64))
        (location (string-utf8 256))
    )
    (let ((caller tx-sender))
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (is-none (map-get? water-meters caller))
                ERR_ALREADY_REGISTERED
            )
            (map-set water-meters caller {
                meter-id: meter-id,
                location: location,
                installed-at: stacks-block-height,
                is-active: true,
                total-consumption: u0,
            })
            (map-set user-balances caller {
                total-tokens: u0,
                total-consumption: u0,
                registration-date: stacks-block-height,
                tier-level: u1,
            })
            (print {
                action: "meter-registered",
                owner: caller,
                meter-id: meter-id,
            })
            (ok true)
        )
    )
)

(define-public (submit-water-reading
        (consumption-amount uint)
        (reading-type (string-ascii 32))
    )
    (let (
            (caller tx-sender)
            (reading-id (var-get next-reading-id))
            (current-block stacks-block-height)
        )
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (> consumption-amount u0) ERR_INVALID_AMOUNT)
            (asserts! (is-some (map-get? water-meters caller)) ERR_NOT_REGISTERED)
            (map-set water-readings reading-id {
                meter-owner: caller,
                meter-id: (unwrap-panic (get meter-id (map-get? water-meters caller))),
                reading-date: current-block,
                consumption-amount: consumption-amount,
                reading-type: reading-type,
                validated: false,
                validator: none,
            })
            (var-set next-reading-id (+ reading-id u1))
            (print {
                action: "reading-submitted",
                owner: caller,
                reading-id: reading-id,
                amount: consumption-amount,
            })
            (ok reading-id)
        )
    )
)

(define-public (validate-reading
        (reading-id uint)
        (is-valid bool)
    )
    (let (
            (reading (unwrap! (map-get? water-readings reading-id) ERR_READING_NOT_FOUND))
            (caller tx-sender)
        )
        (begin
            (asserts!
                (or
                    (is-eq caller CONTRACT_OWNER)
                    (default-to false
                        (get enabled (map-get? reading-validators caller))
                    )
                )
                ERR_UNAUTHORIZED
            )
            (asserts! (not (get validated reading)) ERR_UNAUTHORIZED)
            (if is-valid
                (begin
                    (try! (process-validated-reading reading-id))
                    (map-set water-readings reading-id
                        (merge reading {
                            validated: true,
                            validator: (some caller),
                        })
                    )
                    (print {
                        action: "reading-validated",
                        reading-id: reading-id,
                        validator: caller,
                    })
                    (ok true)
                )
                (begin
                    (map-delete water-readings reading-id)
                    (print {
                        action: "reading-rejected",
                        reading-id: reading-id,
                        validator: caller,
                    })
                    (ok false)
                )
            )
        )
    )
)

(define-read-only (is-reading-validator (user principal))
    (ok (default-to false (get enabled (map-get? reading-validators user))))
)

(define-public (set-reading-validator
        (user principal)
        (enabled bool)
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (if enabled
            (begin
                (map-set reading-validators user { enabled: true })
                (ok true)
            )
            (begin
                (map-delete reading-validators user)
                (ok true)
            )
        )
    )
)

(define-private (process-validated-reading (reading-id uint))
    (let (
            (reading (unwrap-panic (map-get? water-readings reading-id)))
            (owner (get meter-owner reading))
            (consumption (get consumption-amount reading))
            (tokens-to-mint (unwrap-panic (calculate-tokens-for-consumption consumption)))
        )
        (begin
            (try! (ft-mint? water-usage-token tokens-to-mint owner))
            (update-user-consumption owner consumption)
            (update-meter-consumption owner consumption)
            (var-set total-water-consumed
                (+ (var-get total-water-consumed) consumption)
            )
            (ok true)
        )
    )
)

(define-private (update-user-consumption
        (user principal)
        (consumption uint)
    )
    (match (map-get? user-balances user)
        user-data (let (
                (new-total (+ (get total-consumption user-data) consumption))
                (new-tokens (+ (get total-tokens user-data)
                    (unwrap-panic (calculate-tokens-for-consumption consumption))
                ))
                (new-tier (calculate-tier new-total))
            )
            (map-set user-balances user
                (merge user-data {
                    total-tokens: new-tokens,
                    total-consumption: new-total,
                    tier-level: new-tier,
                })
            )
        )
        false
    )
)

(define-private (update-meter-consumption
        (owner principal)
        (consumption uint)
    )
    (match (map-get? water-meters owner)
        meter-data (map-set water-meters owner
            (merge meter-data { total-consumption: (+ (get total-consumption meter-data) consumption) })
        )
        false
    )
)

(define-private (calculate-tier (total-consumption uint))
    (if (>= total-consumption u10000)
        u5
        (if (>= total-consumption u5000)
            u4
            (if (>= total-consumption u2000)
                u3
                (if (>= total-consumption u500)
                    u2
                    u1
                )
            )
        )
    )
)

(define-public (purchase-tokens (amount uint))
    (let (
            (caller tx-sender)
            (cost (* amount (var-get token-price)))
        )
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (> amount u0) ERR_INVALID_AMOUNT)
            (try! (stx-transfer? cost caller CONTRACT_OWNER))
            (try! (ft-mint? water-usage-token amount caller))
            (print {
                action: "tokens-purchased",
                buyer: caller,
                amount: amount,
                cost: cost,
            })
            (ok true)
        )
    )
)

(define-public (redeem-tokens (amount uint))
    (let (
            (caller tx-sender)
            (refund (* amount (/ (var-get token-price) u2)))
        )
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (> amount u0) ERR_INVALID_AMOUNT)
            (asserts! (>= (ft-get-balance water-usage-token caller) amount)
                ERR_INSUFFICIENT_TOKENS
            )
            (try! (ft-burn? water-usage-token amount caller))
            (try! (as-contract (stx-transfer? refund tx-sender caller)))
            (print {
                action: "tokens-redeemed",
                user: caller,
                amount: amount,
                refund: refund,
            })
            (ok true)
        )
    )
)

(define-public (set-meter-status
        (owner principal)
        (active bool)
    )
    (let ((caller tx-sender))
        (begin
            (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (match (map-get? water-meters owner)
                meter-data (begin
                    (map-set water-meters owner
                        (merge meter-data { is-active: active })
                    )
                    (print {
                        action: "meter-status-updated",
                        owner: owner,
                        active: active,
                    })
                    (ok true)
                )
                ERR_METER_NOT_FOUND
            )
        )
    )
)

(define-public (update-token-price (new-price uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (> new-price u0) ERR_INVALID_AMOUNT)
        (var-set token-price new-price)
        (print {
            action: "price-updated",
            new-price: new-price,
        })
        (ok true)
    )
)

(define-public (set-consumption-reward
        (tier uint)
        (min-consumption uint)
        (max-consumption uint)
        (reward-rate uint)
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (> tier u0) ERR_INVALID_AMOUNT)
        (asserts! (< min-consumption max-consumption) ERR_INVALID_AMOUNT)
        (map-set consumption-rewards tier {
            tier: tier,
            min-consumption: min-consumption,
            max-consumption: max-consumption,
            reward-rate: reward-rate,
        })
        (print {
            action: "reward-tier-set",
            tier: tier,
            rate: reward-rate,
        })
        (ok true)
    )
)

(define-public (set-usage-penalty
        (penalty-id uint)
        (penalty-type (string-ascii 32))
        (threshold uint)
        (penalty-rate uint)
        (description (string-utf8 256))
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (> threshold u0) ERR_INVALID_AMOUNT)
        (map-set usage-penalties penalty-id {
            penalty-type: penalty-type,
            threshold: threshold,
            penalty-rate: penalty-rate,
            description: description,
        })
        (print {
            action: "penalty-set",
            penalty-id: penalty-id,
            type: penalty-type,
        })
        (ok true)
    )
)

(define-public (apply-consumption-reward (user principal))
    (let (
            (user-data (unwrap! (map-get? user-balances user) ERR_NOT_REGISTERED))
            (total-consumption (get total-consumption user-data))
            (tier (get tier-level user-data))
        )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (match (map-get? consumption-rewards tier)
                reward-data (if (and
                        (>= total-consumption (get min-consumption reward-data))
                        (<= total-consumption (get max-consumption reward-data))
                    )
                    (let ((reward-amount (* total-consumption (get reward-rate reward-data))))
                        (try! (ft-mint? water-usage-token reward-amount user))
                        (print {
                            action: "reward-applied",
                            user: user,
                            tier: tier,
                            amount: reward-amount,
                        })
                        (ok reward-amount)
                    )
                    (ok u0)
                )
                (ok u0)
            )
        )
    )
)

(define-public (apply-usage-penalty
        (user principal)
        (penalty-id uint)
    )
    (let (
            (user-data (unwrap! (map-get? user-balances user) ERR_NOT_REGISTERED))
            (penalty-data (unwrap! (map-get? usage-penalties penalty-id) ERR_INVALID_USAGE_TYPE))
            (total-consumption (get total-consumption user-data))
            (user-balance (ft-get-balance water-usage-token user))
        )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (if (>= total-consumption (get threshold penalty-data))
                (let ((penalty-amount (/ (* user-balance (get penalty-rate penalty-data)) u100)))
                    (if (> penalty-amount u0)
                        (begin
                            (try! (ft-burn? water-usage-token penalty-amount user))
                            (print {
                                action: "penalty-applied",
                                user: user,
                                penalty-id: penalty-id,
                                amount: penalty-amount,
                            })
                            (ok penalty-amount)
                        )
                        (ok u0)
                    )
                )
                (ok u0)
            )
        )
    )
)

(define-public (batch-validate-readings
        (reading-ids (list 50 uint))
        (validations (list 50 bool))
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-eq (len reading-ids) (len validations)) ERR_INVALID_AMOUNT)
        (ok (map validate-single-reading reading-ids validations))
    )
)

(define-private (validate-single-reading
        (reading-id uint)
        (is-valid bool)
    )
    (match (validate-reading reading-id is-valid)
        success
        success
        error
        false
    )
)

(define-public (emergency-pause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused true)
        (print {
            action: "contract-paused",
            by: tx-sender,
        })
        (ok true)
    )
)

(define-public (emergency-unpause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused false)
        (print {
            action: "contract-unpaused",
            by: tx-sender,
        })
        (ok true)
    )
)

(define-public (bulk-mint-tokens
        (recipients (list 50 principal))
        (amounts (list 50 uint))
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-eq (len recipients) (len amounts)) ERR_INVALID_AMOUNT)
        (ok (map mint-to-recipient recipients amounts))
    )
)

(define-private (mint-to-recipient
        (recipient principal)
        (amount uint)
    )
    (match (ft-mint? water-usage-token amount recipient)
        success
        true
        error
        false
    )
)

(define-public (get-monthly-consumption
        (user principal)
        (month uint)
        (year uint)
    )
    (let ((user-data (unwrap! (map-get? user-balances user) ERR_NOT_REGISTERED)))
        (ok (filter-readings-by-month user month year))
    )
)

(define-private (filter-readings-by-month
        (user principal)
        (month uint)
        (year uint)
    )
    u0
)

(define-public (set-token-uri (new-uri (optional (string-utf8 256))))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set token-uri new-uri)
        (print {
            action: "token-uri-updated",
            uri: new-uri,
        })
        (ok true)
    )
)

(define-public (get-meter-efficiency (owner principal))
    (match (map-get? water-meters owner)
        meter-data (let (
                (total-consumption (get total-consumption meter-data))
                (installation-block (get installed-at meter-data))
                (blocks-active (- stacks-block-height installation-block))
            )
            (if (> blocks-active u0)
                (ok (/ total-consumption blocks-active))
                (ok u0)
            )
        )
        ERR_METER_NOT_FOUND
    )
)

(define-public (transfer-meter-ownership (new-owner principal))
    (let (
            (caller tx-sender)
            (meter-data (unwrap! (map-get? water-meters caller) ERR_METER_NOT_FOUND))
        )
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (not (is-eq caller new-owner)) ERR_INVALID_RECIPIENT)
            (asserts! (is-none (map-get? water-meters new-owner))
                ERR_ALREADY_REGISTERED
            )
            (map-delete water-meters caller)
            (map-set water-meters new-owner meter-data)
            (print {
                action: "meter-transferred",
                from: caller,
                to: new-owner,
            })
            (ok true)
        )
    )
)

(define-public (deactivate-meter)
    (let (
            (caller tx-sender)
            (meter-data (unwrap! (map-get? water-meters caller) ERR_METER_NOT_FOUND))
        )
        (begin
            (map-set water-meters caller (merge meter-data { is-active: false }))
            (print {
                action: "meter-deactivated",
                owner: caller,
            })
            (ok true)
        )
    )
)

(define-public (get-reading-history
        (user principal)
        (limit uint)
    )
    (let ((user-data (unwrap! (map-get? user-balances user) ERR_NOT_REGISTERED)))
        (ok (get-user-readings user limit))
    )
)

(define-private (get-user-readings
        (user principal)
        (limit uint)
    )
    (list)
)

(define-public (calculate-water-bill (user principal))
    (match (map-get? user-balances user)
        user-data (let (
                (consumption (get total-consumption user-data))
                (base-cost (* consumption u50))
                (tier-multiplier (get tier-level user-data))
            )
            (ok (* base-cost tier-multiplier))
        )
        ERR_NOT_REGISTERED
    )
)

(define-public (emergency-withdraw-stx (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER)))
        (print {
            action: "emergency-withdrawal",
            amount: amount,
        })
        (ok true)
    )
)

(define-public (create-conservation-challenge
        (title (string-utf8 128))
        (description (string-utf8 256))
        (duration-blocks uint)
        (target-reduction uint)
        (reward-pool uint)
    )
    (let (
            (challenge-id (var-get next-challenge-id))
            (start-block stacks-block-height)
            (end-block (+ start-block duration-blocks))
        )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (asserts! (> duration-blocks u0) ERR_INVALID_AMOUNT)
            (asserts! (> target-reduction u0) ERR_INVALID_AMOUNT)
            (asserts! (> reward-pool u0) ERR_INVALID_AMOUNT)
            (map-set conservation-challenges challenge-id {
                challenge-id: challenge-id,
                title: title,
                description: description,
                start-block: start-block,
                end-block: end-block,
                target-reduction: target-reduction,
                reward-pool: reward-pool,
                participant-count: u0,
                is-active: true,
                creator: tx-sender,
            })
            (var-set next-challenge-id (+ challenge-id u1))
            (print {
                action: "challenge-created",
                challenge-id: challenge-id,
                title: title,
            })
            (ok challenge-id)
        )
    )
)

(define-public (join-conservation-challenge (challenge-id uint))
    (let (
            (challenge (unwrap! (map-get? conservation-challenges challenge-id)
                ERR_CHALLENGE_NOT_FOUND
            ))
            (user-data (unwrap! (map-get? user-balances tx-sender) ERR_NOT_REGISTERED))
            (participant-key {
                challenge-id: challenge-id,
                participant: tx-sender,
            })
        )
        (begin
            (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
            (asserts! (get is-active challenge) ERR_CHALLENGE_ENDED)
            (asserts! (< stacks-block-height (get end-block challenge))
                ERR_CHALLENGE_ENDED
            )
            (asserts! (is-none (map-get? challenge-participants participant-key))
                ERR_ALREADY_JOINED_CHALLENGE
            )
            (map-set challenge-participants participant-key {
                baseline-consumption: (get total-consumption user-data),
                current-consumption: u0,
                reduction-achieved: u0,
                joined-at: stacks-block-height,
                reward-claimed: false,
            })
            (map-set conservation-challenges challenge-id
                (merge challenge { participant-count: (+ (get participant-count challenge) u1) })
            )
            (print {
                action: "challenge-joined",
                challenge-id: challenge-id,
                participant: tx-sender,
            })
            (ok true)
        )
    )
)

(define-public (update-challenge-progress (challenge-id uint))
    (let (
            (challenge (unwrap! (map-get? conservation-challenges challenge-id)
                ERR_CHALLENGE_NOT_FOUND
            ))
            (participant-key {
                challenge-id: challenge-id,
                participant: tx-sender,
            })
            (participant-data (unwrap! (map-get? challenge-participants participant-key)
                ERR_NOT_JOINED_CHALLENGE
            ))
            (user-data (unwrap! (map-get? user-balances tx-sender) ERR_NOT_REGISTERED))
            (baseline (get baseline-consumption participant-data))
            (current-total (get total-consumption user-data))
            (reduction (if (> baseline current-total)
                (- baseline current-total)
                u0
            ))
        )
        (begin
            (asserts! (get is-active challenge) ERR_CHALLENGE_ENDED)
            (map-set challenge-participants participant-key
                (merge participant-data {
                    current-consumption: current-total,
                    reduction-achieved: reduction,
                })
            )
            (print {
                action: "challenge-progress-updated",
                challenge-id: challenge-id,
                participant: tx-sender,
                reduction: reduction,
            })
            (ok reduction)
        )
    )
)

(define-public (claim-challenge-reward (challenge-id uint))
    (let (
            (challenge (unwrap! (map-get? conservation-challenges challenge-id)
                ERR_CHALLENGE_NOT_FOUND
            ))
            (participant-key {
                challenge-id: challenge-id,
                participant: tx-sender,
            })
            (participant-data (unwrap! (map-get? challenge-participants participant-key)
                ERR_NOT_JOINED_CHALLENGE
            ))
            (reduction (get reduction-achieved participant-data))
            (target (get target-reduction challenge))
        )
        (begin
            (asserts! (>= stacks-block-height (get end-block challenge))
                ERR_CHALLENGE_ACTIVE
            )
            (asserts! (not (get reward-claimed participant-data))
                ERR_UNAUTHORIZED
            )
            (asserts! (>= reduction target) ERR_INSUFFICIENT_TOKENS)
            (let (
                    (reward-amount (/ (get reward-pool challenge)
                        (get participant-count challenge)
                    ))
                    (bonus-reward (/ (* reduction u5) u100))
                    (total-reward (+ reward-amount bonus-reward))
                )
                (try! (ft-mint? water-usage-token total-reward tx-sender))
                (map-set challenge-participants participant-key
                    (merge participant-data { reward-claimed: true })
                )
                (print {
                    action: "challenge-reward-claimed",
                    challenge-id: challenge-id,
                    participant: tx-sender,
                    reward: total-reward,
                })
                (ok total-reward)
            )
        )
    )
)

(define-public (end-conservation-challenge (challenge-id uint))
    (let ((challenge (unwrap! (map-get? conservation-challenges challenge-id)
            ERR_CHALLENGE_NOT_FOUND
        )))
        (begin
            (asserts! (is-eq tx-sender (get creator challenge)) ERR_UNAUTHORIZED)
            (asserts! (>= stacks-block-height (get end-block challenge))
                ERR_CHALLENGE_ACTIVE
            )
            (map-set conservation-challenges challenge-id
                (merge challenge { is-active: false })
            )
            (print {
                action: "challenge-ended",
                challenge-id: challenge-id,
            })
            (ok true)
        )
    )
)

(map-set consumption-rewards u1 {
    tier: u1,
    min-consumption: u0,
    max-consumption: u500,
    reward-rate: u10,
})
(map-set consumption-rewards u2 {
    tier: u2,
    min-consumption: u501,
    max-consumption: u2000,
    reward-rate: u15,
})
(map-set consumption-rewards u3 {
    tier: u3,
    min-consumption: u2001,
    max-consumption: u5000,
    reward-rate: u20,
})
(map-set consumption-rewards u4 {
    tier: u4,
    min-consumption: u5001,
    max-consumption: u10000,
    reward-rate: u25,
})
(map-set consumption-rewards u5 {
    tier: u5,
    min-consumption: u10001,
    max-consumption: u999999,
    reward-rate: u30,
})

(map-set usage-penalties u1 {
    penalty-type: "excessive",
    threshold: u15000,
    penalty-rate: u10,
    description: u"Penalty for excessive water usage",
})
(map-set usage-penalties u2 {
    penalty-type: "wasteful",
    threshold: u20000,
    penalty-rate: u15,
    description: u"Penalty for wasteful water practices",
})
(map-set usage-penalties u3 {
    penalty-type: "commercial",
    threshold: u50000,
    penalty-rate: u5,
    description: u"Commercial usage penalty",
})
