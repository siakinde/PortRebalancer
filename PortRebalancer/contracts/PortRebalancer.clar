;; Tokenized Portfolio Rebalancing Smart Contract
;; A comprehensive smart contract for managing tokenized portfolios with automatic rebalancing capabilities.
;; Supports multiple tokens, configurable target allocations, fee management, and secure rebalancing operations.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-percentage (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-token (err u105))
(define-constant err-portfolio-not-found (err u106))
(define-constant err-slippage-exceeded (err u107))
(define-constant err-invalid-amount (err u108))
(define-constant err-deadline-exceeded (err u109))
(define-constant err-rebalance-not-needed (err u110))

(define-constant max-tokens u20)
(define-constant max-percentage u10000) ;; 100.00% in basis points
(define-constant min-rebalance-threshold u100) ;; 1.00% minimum deviation
(define-constant base-fee u50) ;; 0.50% base fee
(define-constant max-slippage u500) ;; 5.00% maximum slippage

;; Data Maps and Variables
(define-map portfolios
  { portfolio-id: uint }
  {
    owner: principal,
    name: (string-ascii 64),
    total-value: uint,
    last-rebalance: uint,
    active: bool,
    performance-fee: uint
  }
)

(define-map portfolio-allocations
  { portfolio-id: uint, token-contract: principal }
  {
    target-percentage: uint,
    current-percentage: uint,
    current-amount: uint,
    token-symbol: (string-ascii 12)
  }
)

(define-map user-balances
  { user: principal, portfolio-id: uint }
  {
    shares: uint,
    initial-deposit: uint,
    deposit-block: uint
  }
)

(define-map approved-tokens
  { token-contract: principal }
  {
    symbol: (string-ascii 12),
    decimals: uint,
    active: bool,
    oracle-price: uint
  }
)

(define-map rebalance-history
  { portfolio-id: uint, rebalance-id: uint }
  {
    timestamp: uint,
    gas-used: uint,
    tokens-traded: uint,
    total-fees: uint,
    initiator: principal
  }
)

(define-data-var next-portfolio-id uint u1)
(define-data-var next-rebalance-id uint u1)
(define-data-var protocol-fee-recipient principal contract-owner)
(define-data-var emergency-pause bool false)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (calculate-deviation (target uint) (current uint))
  (if (> target current)
    (- target current)
    (- current target)
  )
)

(define-private (get-token-value (token-contract principal) (amount uint))
  (match (map-get? approved-tokens { token-contract: token-contract })
    token-info (/ (* amount (get oracle-price token-info)) u1000000)
    u0
  )
)

(define-private (calculate-rebalance-fee (portfolio-value uint) (deviation uint))
  (let ((base-fee-amount (/ (* portfolio-value base-fee) u10000)))
    (+ base-fee-amount (/ (* portfolio-value deviation) u100000))
  )
)

(define-private (check-rebalancing-needed (portfolio-id uint))
  (let ((portfolio (unwrap-panic (map-get? portfolios { portfolio-id: portfolio-id }))))
    (> (- block-height (get last-rebalance portfolio)) u144) ;; 24 hours in blocks
  )
)

;; Public Functions
(define-public (create-portfolio (name (string-ascii 64)) (performance-fee uint))
  (let ((portfolio-id (var-get next-portfolio-id)))
    (asserts! (not (var-get emergency-pause)) (err u999))
    (asserts! (<= performance-fee u2000) err-invalid-percentage) ;; Max 20% performance fee
    (map-set portfolios
      { portfolio-id: portfolio-id }
      {
        owner: tx-sender,
        name: name,
        total-value: u0,
        last-rebalance: block-height,
        active: true,
        performance-fee: performance-fee
      }
    )
    (var-set next-portfolio-id (+ portfolio-id u1))
    (ok portfolio-id)
  )
)

(define-public (add-token-allocation (portfolio-id uint) (token-contract principal) (target-percentage uint) (token-symbol (string-ascii 12)))
  (let ((portfolio (unwrap! (map-get? portfolios { portfolio-id: portfolio-id }) err-portfolio-not-found)))
    (asserts! (is-eq tx-sender (get owner portfolio)) err-unauthorized)
    (asserts! (is-some (map-get? approved-tokens { token-contract: token-contract })) err-invalid-token)
    (asserts! (and (> target-percentage u0) (<= target-percentage max-percentage)) err-invalid-percentage)
    (map-set portfolio-allocations
      { portfolio-id: portfolio-id, token-contract: token-contract }
      {
        target-percentage: target-percentage,
        current-percentage: u0,
        current-amount: u0,
        token-symbol: token-symbol
      }
    )
    (ok true)
  )
)

(define-public (approve-token (token-contract principal) (symbol (string-ascii 12)) (decimals uint))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (map-set approved-tokens
      { token-contract: token-contract }
      {
        symbol: symbol,
        decimals: decimals,
        active: true,
        oracle-price: u1000000 ;; Default $1 price, should be updated by oracle
      }
    )
    (ok true)
  )
)

(define-public (deposit-to-portfolio (portfolio-id uint) (amount uint))
  (let ((portfolio (unwrap! (map-get? portfolios { portfolio-id: portfolio-id }) err-portfolio-not-found)))
    (asserts! (get active portfolio) err-not-found)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (var-get emergency-pause)) (err u999))
    
    (let ((current-shares (default-to u0 (get shares (map-get? user-balances { user: tx-sender, portfolio-id: portfolio-id }))))
          (total-value (get total-value portfolio))
          (new-shares (if (is-eq total-value u0) amount (/ (* amount u1000000) total-value))))
      
      (map-set user-balances
        { user: tx-sender, portfolio-id: portfolio-id }
        {
          shares: (+ current-shares new-shares),
          initial-deposit: amount,
          deposit-block: block-height
        }
      )
      
      (map-set portfolios
        { portfolio-id: portfolio-id }
        (merge portfolio { total-value: (+ total-value amount) })
      )
      
      (ok new-shares)
    )
  )
)

(define-public (emergency-pause-toggle)
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (var-set emergency-pause (not (var-get emergency-pause)))
    (ok (var-get emergency-pause))
  )
)


