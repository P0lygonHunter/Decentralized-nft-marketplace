# Decentralized-nft-marketplace
Advanced NFT marketplace with EIP-712 signatures, escrow settlement, and MEV-resistant design.

# Decentralized NFT Marketplace (Advanced EIP-712 + Escrow Design)

## Overview

This project implements a production-grade NFT marketplace using Solidity, focused on secure, gas-efficient, and adversarially resilient design patterns.

The system enables trustless trading of ERC721 assets using off-chain signed orders, escrow-based settlements, and MEV-resistant listing mechanisms.

---

## Core Features

* EIP-712 based off-chain order signing
* Signature-verified on-chain execution
* Pull-payment escrow architecture
* ERC2981 royalty distribution
* Anti front-running via commit-reveal scheme
* Non-custodial NFT ownership model
* Gas-optimized storage packing

---

## Architecture Design

### Off-chain Orderbook

Sellers sign orders off-chain using EIP-712 typed data. Buyers execute orders on-chain.

### Escrow Settlement

Funds are stored and withdrawn via a pull-based mechanism, preventing reentrancy and gas griefing.

### Royalty Engine

Built-in ERC2981 support ensures creators receive royalties on every sale.

### MEV Resistance

Commit-reveal mechanism prevents front-running attacks.

---

## Smart Contract

```solidity
// Contract code available in /contracts/NexusV3.sol
```

---

## Security Focus

* Reentrancy protection
* Signature replay protection
* Ownership verification
* Escrow-based fund safety

---

## Tech Stack

* Solidity ^0.8.x
* OpenZeppelin Contracts
* EIP-712 Signing
* ERC721 + ERC2981

---

## Author

Bug Bounty Hunter & Security Researcher | Specialized in ZK-Circuits & Smart Contract Auditing.
