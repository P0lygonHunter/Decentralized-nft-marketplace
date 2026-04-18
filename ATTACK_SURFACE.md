# Attack Surface Analysis

## Overview

This document outlines potential attack vectors considered during the design of the NFT marketplace, along with the mitigation strategies implemented in the smart contract.

The system is designed under an adversarial model where every interaction is treated as potentially malicious.

---

## 1. Reentrancy Attacks

### Attack Vector

An attacker attempts to re-enter the contract during ETH transfer to manipulate state or drain funds.

### Mitigation

* `ReentrancyGuard` is applied to all sensitive external functions (`buy`, `buyWithSig`, `withdraw`)
* Pull-payment model ensures no direct external calls during critical state changes

---

## 2. Signature Replay Attacks

### Attack Vector

Reusing a valid signed order multiple times to execute unintended purchases.

### Mitigation

* Per-user nonce system (`nonces[address]`)
* Nonce is incremented on every successful execution
* Prevents reuse of previously signed messages

---

## 3. Front-Running (MEV Exploitation)

### Attack Vector

A malicious actor observes a pending transaction and executes it first with higher gas.

### Mitigation

* Commit-reveal scheme:

  * Buyer first commits a hashed order
  * Execution requires prior commitment
* Prevents transaction sniping and order hijacking

---

## 4. Forced Asset Transfer

### Attack Vector

Buyer purchases an NFT without explicit seller consent.

### Mitigation

* EIP-712 signature verification ensures seller authorization
* Orders must be signed off-chain by the asset owner

---

## 5. Payment Griefing / DoS via Transfer

### Attack Vector

Using contracts with failing fallback functions to block ETH transfers.

### Mitigation

* No direct ETH transfers
* Pull-payment escrow model (`pendingWithdrawals`)
* Users withdraw funds manually

---

## 6. Stale Listing Exploit

### Attack Vector

Seller lists NFT, transfers it elsewhere, but listing remains active.

### Mitigation

* Ownership is re-validated during purchase:

  * `require(ownerOf(tokenId) == seller)`

---

## 7. Overpayment Exploit

### Attack Vector

Users accidentally send excess ETH with no refund.

### Mitigation

* Automatic refund of surplus ETH after purchase execution

---

## 8. Royalty Manipulation

### Attack Vector

Bypassing royalty payments during secondary sales.

### Mitigation

* Native integration of ERC2981
* Royalty enforced at contract level

---

## 9. Unauthorized Listing

### Attack Vector

A user attempts to list NFTs they do not own.

### Mitigation

* Ownership validation:

  * `require(ownerOf(tokenId) == msg.sender)`

---

## 10. Expired Order Execution

### Attack Vector

Executing outdated signed orders after intended validity period.

### Mitigation

* Timestamp-based expiry validation in all order executions

---

## Security Philosophy

The system is designed with the assumption that:

* All users may act maliciously
* Transactions are observable and can be front-run
* External calls are untrusted by default

Security is enforced through:

* Explicit validation
* Minimal trust assumptions
* Defensive programming patterns

---

## Conclusion

This marketplace architecture prioritizes:

* Trustless execution
* Exploit resistance
* Predictable behavior under adversarial conditions

The goal is not just functionality, but resilience against real-world attack scenarios.

