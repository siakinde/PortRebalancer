**PortRebalancer**
---

A robust Clarity smart contract designed for managing tokenized portfolios with automated rebalancing capabilities on the Stacks blockchain. This contract facilitates the creation and management of diverse token portfolios, allowing users to define target allocations for various tokens. It includes features for fee management, slippage protection, and secure rebalancing operations.

---

## Table of Contents

-   Features
-   Error Codes
-   Constants
-   Data Maps and Variables
-   Public Functions
-   Usage
-   Deployment
-   Contributing
-   License
-   Security

---

## Features

* **Portfolio Creation**: Users can create and name their tokenized portfolios.
* **Configurable Allocations**: Define target percentage allocations for multiple approved tokens within a portfolio.
* **Automatic Rebalancing**: The `execute-advanced-rebalance` function allows for comprehensive rebalancing of portfolio assets based on predefined deviations and includes slippage protection.
* **Fee Management**: Incorporates a base fee and a performance-based fee for rebalancing operations.
* **Token Management**: Contract owner can approve and manage supported tokens, including their symbols, decimals, and oracle prices.
* **User Deposits**: Users can deposit funds into portfolios, receiving shares in return.
* **Emergency Pause**: A mechanism for the contract owner to pause critical functionalities in case of emergencies.
* **Detailed History**: Records rebalancing events, including timestamps, gas usage, tokens traded, and fees.

---

## Error Codes

| Code | Name | Description |
| :--- | :------------------------- | :------------------------------------------- |
| `u100` | `err-owner-only` | Only the contract owner can call this function. |
| `u101` | `err-not-found` | The requested item was not found. |
| `u102` | `err-unauthorized` | The sender is not authorized to perform this action. |
| `u103` | `err-invalid-percentage` | The provided percentage is invalid. |
| `u104` | `err-insufficient-balance` | Insufficient balance for the operation. |
| `u105` | `err-invalid-token` | The specified token is not valid or approved. |
| `u106` | `err-portfolio-not-found` | The specified portfolio ID does not exist. |
| `u107` | `err-slippage-exceeded` | The transaction's slippage limit was exceeded. |
| `u108` | `err-invalid-amount` | The provided amount is invalid. |
| `u109` | `err-deadline-exceeded` | The transaction deadline has passed. |
| `u110` | `err-rebalance-not-needed` | Rebalancing is not currently needed for this portfolio. |
| `u999` | `emergency-pause` | The contract is currently paused due to an emergency. |

---

## Constants

* `contract-owner`: The principal of the contract deployer.
* `max-tokens`: `u20` (Maximum number of tokens allowed in a portfolio).
* `max-percentage`: `u10000` (Represents 100.00% in basis points for allocations).
* `min-rebalance-threshold`: `u100` (1.00% minimum deviation required to trigger rebalance).
* `base-fee`: `u50` (0.50% base fee for rebalancing).
* `max-slippage`: `u500` (5.00% maximum allowed slippage during trades).

---

## Data Maps and Variables

* **`portfolios`**: A map storing portfolio details by `portfolio-id`.
    * `owner`: The principal who owns the portfolio.
    * `name`: ASCII string (max 64 chars) for the portfolio name.
    * `total-value`: Current total value of the portfolio in a normalized unit (e.g., USD cents).
    * `last-rebalance`: Block height of the last rebalance.
    * `active`: Boolean indicating if the portfolio is active.
    * `performance-fee`: Percentage performance fee for the portfolio.
* **`portfolio-allocations`**: A map storing allocation details for each token within a portfolio.
    * `portfolio-id`: The ID of the portfolio.
    * `token-contract`: The principal of the token contract.
    * `target-percentage`: The desired percentage allocation for the token.
    * `current-percentage`: The current percentage allocation for the token.
    * `current-amount`: The current amount of the token held in the portfolio.
    * `token-symbol`: ASCII string (max 12 chars) for the token's symbol.
* **`user-balances`**: A map tracking user-specific balances within portfolios.
    * `user`: The principal of the user.
    * `portfolio-id`: The ID of the portfolio.
    * `shares`: Number of shares the user holds in the portfolio.
    * `initial-deposit`: The initial deposit amount by the user.
    * `deposit-block`: Block height of the initial deposit.
* **`approved-tokens`**: A map of tokens approved by the contract owner for use in portfolios.
    * `token-contract`: The principal of the token contract.
    * `symbol`: ASCII string (max 12 chars) for the token's symbol.
    * `decimals`: Number of decimals for the token.
    * `active`: Boolean indicating if the token is active.
    * `oracle-price`: The token's price, expected to be updated by an oracle.
* **`rebalance-history`**: A map recording details of each rebalancing event.
    * `portfolio-id`: The ID of the portfolio.
    * `rebalance-id`: The unique ID of the rebalance event.
    * `timestamp`: Block height of the rebalance event.
    * `gas-used`: Estimated gas used for the rebalance.
    * `tokens-traded`: Number of tokens involved in the rebalance trades.
    * `total-fees`: Total fees incurred during the rebalance.
    * `initiator`: The principal who initiated the rebalance.
* **`next-portfolio-id`**: Data variable, `uint`, tracks the next available portfolio ID. Initialized to `u1`.
* **`next-rebalance-id`**: Data variable, `uint`, tracks the next available rebalance ID. Initialized to `u1`.
* **`protocol-fee-recipient`**: Data variable, `principal`, where protocol fees are sent. Initialized to `contract-owner`.
* **`emergency-pause`**: Data variable, `bool`, indicates if the contract is paused. Initialized to `false`.

---

## Public Functions

### `create-portfolio (name (string-ascii 64)) (performance-fee uint)`

Creates a new tokenized portfolio.

* **Parameters**:
    * `name`: The desired name for the portfolio.
    * `performance-fee`: The performance fee percentage (in basis points, max 2000 for 20%).
* **Returns**: `(ok uint)` the new portfolio ID on success, or an error.

### `add-token-allocation (portfolio-id uint) (token-contract principal) (target-percentage uint) (token-symbol (string-ascii 12))`

Adds or updates the target allocation for a specific token within a portfolio.

* **Parameters**:
    * `portfolio-id`: The ID of the portfolio.
    * `token-contract`: The principal of the token to allocate.
    * `target-percentage`: The desired target percentage for this token (in basis points).
    * `token-symbol`: The symbol of the token.
* **Returns**: `(ok true)` on success, or an error.

### `approve-token (token-contract principal) (symbol (string-ascii 12)) (decimals uint)`

Approves a new token for use within the portfolios. Only callable by the contract owner.

* **Parameters**:
    * `token-contract`: The principal of the token to approve.
    * `symbol`: The symbol of the token.
    * `decimals`: The number of decimals of the token.
* **Returns**: `(ok true)` on success, or an error.

### `deposit-to-portfolio (portfolio-id uint) (amount uint)`

Allows users to deposit funds into a specified portfolio and receive shares.

* **Parameters**:
    * `portfolio-id`: The ID of the portfolio to deposit into.
    * `amount`: The amount of tokens to deposit.
* **Returns**: `(ok uint)` the number of shares received on success, or an error.

### `emergency-pause-toggle ()`

Toggles the emergency pause state of the contract. Only callable by the contract owner. When paused, certain critical functions are disabled.

* **Parameters**: None.
* **Returns**: `(ok bool)` the new pause state on success, or an error.

### `execute-advanced-rebalance (portfolio-id uint) (token-trades (list 20 { token: principal, action: (string-ascii 4), amount: uint, min-received: uint })) (slippage-limit uint) (deadline uint)`

Executes a multi-token rebalancing operation for a portfolio with built-in slippage protection and batch processing.

* **Parameters**:
    * `portfolio-id`: The ID of the portfolio to rebalance.
    * `token-trades`: A list of trade instructions, each specifying the token, action (e.g., "buy" or "sell"), amount, and minimum amount to receive (for slippage protection).
    * `slippage-limit`: The maximum allowed slippage for the entire rebalance operation (in basis points).
    * `deadline`: The block height by which the rebalance must be executed.
* **Returns**: `(ok { rebalance-id: uint, total-fees: uint, trades-executed: uint, new-portfolio-value: uint })` on success, or an error.

---

## Usage

This contract is designed to be integrated with off-chain systems that monitor portfolio deviations and initiate rebalancing.

1.  **Deployment**: Deploy the contract to the Stacks blockchain. The deployer automatically becomes the **contract-owner**.
2.  **Token Approval**: The **contract-owner** must approve all desired tokens using `approve-token` before they can be used in portfolios.
3.  **Portfolio Creation**: Users or portfolio managers create portfolios using `create-portfolio`.
4.  **Allocation Definition**: For each created portfolio, define target token allocations using `add-token-allocation`.
5.  **Deposits**: Users deposit tokens into portfolios using `deposit-to-portfolio`.
6.  **Rebalancing**: An off-chain service or authorized principal can call `execute-advanced-rebalance` when a portfolio deviates from its target allocations. This function simulates the rebalance and updates the portfolio's state, including fees and new value. (Note: The actual token transfers and swaps would be handled by an integrated DEX or swapping mechanism which is abstracted in this contract for the example.)

---

## Deployment

To deploy this contract:

1.  Set up your Clarity development environment (e.g., using Clarinet).
2.  Compile the `.clar` file.
3.  Deploy the compiled contract to the Stacks blockchain using your preferred deployment method (e.g., Clarinet, Stacks.js, or a block explorer).

---

## Contributing

Contributions are welcome! Please feel free to:

* Open issues for bugs or feature requests.
* Submit pull requests with improvements.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Security

* **Ownership Control**: Critical administrative functions are restricted to the **contract-owner**.
* **Emergency Pause**: A robust `emergency-pause` mechanism is in place to halt sensitive operations during critical situations.
* **Slippage Protection**: The `execute-advanced-rebalance` function includes `slippage-limit` and `min-received` parameters to protect against unfavorable price movements during trades.
* **Input Validation**: Strict input validation is applied to all public functions to prevent common vulnerabilities like integer overflows/underflows and invalid parameters.
* **Oracle Dependency**: The contract relies on an off-chain oracle for `oracle-price` of approved tokens. The security and reliability of this oracle are paramount for accurate portfolio valuation and rebalancing.
* **Assumed External Swap Logic**: The current `execute-advanced-rebalance` function updates internal portfolio states but does *not* directly interact with external DEXs for token swaps. This interaction is assumed to be handled by an external keeper or integrated swap mechanism. Ensure robust, secure integration if building such a system.
