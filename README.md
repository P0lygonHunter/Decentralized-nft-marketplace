# Decentralized NFT Marketplace (Advanced EIP-712 + Escrow Design)

Advanced NFT marketplace with EIP-712 signatures, escrow-based settlement, and MEV-resistant architecture.

---

## Overview

This project implements a production-grade NFT marketplace using Solidity, designed with a strong focus on security, gas efficiency, and adversarial resilience.

The system enables trustless trading of ERC721 assets through off-chain signed orders, secure on-chain execution, and a pull-based escrow settlement model.

---

## Key Insight

This implementation is built with an adversarial mindset, addressing common vulnerabilities in NFT marketplaces such as:

* Forced asset transfers
* Push-based payment failures
* Signature replay attacks
* Front-running and MEV exploitation

The architecture prioritizes trust minimization, execution integrity, and secure value transfer.

---

## Core Features

* EIP-712 based off-chain order signing
* Signature-verified on-chain execution
* Pull-payment escrow architecture
* ERC2981 royalty distribution
* Commit-reveal anti front-running mechanism
* Non-custodial NFT ownership model
* Gas-optimized storage layout

---

## Architecture Design

### Off-chain Orderbook

Sellers sign orders off-chain using EIP-712 typed data. Buyers execute these orders on-chain without requiring direct seller interaction.

### Escrow Settlement

Funds are not transferred directly. Instead, balances are stored within the contract and withdrawn using a pull-based mechanism, preventing reentrancy and gas griefing attacks.

### Royalty Engine

Integrated ERC2981 royalty support ensures creators receive a percentage from every secondary sale.

### MEV Resistance

A commit-reveal scheme is used to mitigate front-running and transaction sniping.

---

## Transaction Flow

1. Seller signs an order off-chain using EIP-712
2. Buyer submits a commitment (anti front-run step)
3. Buyer executes the transaction on-chain
4. Contract verifies signature, nonce, and ownership
5. NFT is transferred securely
6. Funds are allocated to escrow balances
7. Participants withdraw funds via pull-payment

---

## Smart Contract

The core smart contract implementation is available here:

👉 `/contracts/NexusMarket.sol`

---

## Security Considerations

* Reentrancy protection using guard patterns
* Signature replay protection via nonces
* Ownership verification at execution time
* Escrow-based fund isolation (no direct transfers)
* Commit-reveal protection against front-running

---

## Known Trade-offs

* Requires off-chain infrastructure for order signing
* Commit-reveal adds minor UX complexity
* Slight gas overhead due to additional security checks

---

## Tech Stack

* Solidity ^0.8.x
* OpenZeppelin Contracts
* EIP-712 Cryptographic Signing
* ERC721 + ERC2981 Standards

---

## Design Philosophy

Built with a security-first mindset, treating every user interaction as a potential adversarial scenario and designing safeguards accordingly.

---

## Author

​Security-focused smart contract engineer specializing in adversarial analysis, exploit prevention, and resilient Web3 system design.

Focused on building secure, production-ready decentralized systems with a deep understanding of real-world attack surfaces, with additional experience in zero-knowledge systems and advanced cryptographic primitives.

