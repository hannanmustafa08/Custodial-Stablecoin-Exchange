# Custodial-Stablecoin-Exchange

## 📝 Overview
This repository contains the smart contract ecosystem for a hybrid custodial cryptocurrency exchange. It bridges the gap between Decentralized Exchanges (DEX) and Centralized Exchanges (CEX) by combining on-chain transparency and algorithmic pricing with secure, gas-free internal accounting and compliance controls.

## 🏗️ Smart Contract Architecture

The system is highly modular, heavily utilizing inheritance and standardized interfaces (ERC-20, Chainlink AggregatorV3). 

* **`CustodialExchange.sol` (The Custodial Layer)**
  The main entry point for users, which inherits decentralized swapping logic from the base exchange. 
  * **Account Management:** Handles privacy-preserving KYC verification by storing user data as `keccak256` hashes.
  * **Gas-Free Operations:** Facilitates zero-gas internal transactions (`custodialTransfer`) between verified users via logical accounting updates.
  * **Wallet Optimization:** Intelligently maps user balances to specific exchange-controlled wallets to manage pooled liquidity efficiently during trades (`custodialTrade`), deposits, and withdrawals.

* **`CurrencyExchange.sol` (The Decentralized Base)**
  The parent contract that manages the core liquidity pools.
  * **Oracle Integration:** Connects to Chainlink price feeds (`AggregatorV3Interface`) to fetch real-time exchange rates.
  * **Bidirectional Swapping:** Handles the mathematical logic and liquidity checks for trading between the native stablecoin and other registered ERC-20 assets.

* **`StableCoin.sol` (LUMSCoin)**
  The native base currency of the exchange ecosystem.
  * A fully compliant ERC-20 implementation pegged to 1 USD, featuring role-based minting and burning capabilities to manage circulating supply.

* **`MockERC20.sol` & `MockV3Aggregator.sol` (Testing Infrastructure)**
  Utility contracts used strictly for local development and testing. 
  * They simulate external secondary assets and Chainlink decentralized oracle networks, allowing developers to test trading mechanics and price volatility without needing a live testnet deployment.

## ✨ Key Capabilities
1. **Hybrid Trading:** Users can trade assets using the exchange's unified liquidity pool. The system executes real blockchain transactions only when necessary, keeping internal user-to-user transfers strictly logical and free of gas costs.
2. **Secure Deposits & Withdrawals:** Interacts securely with external self-custodied wallets via the `transferFrom` pattern, safely routing tokens into and out of the exchange's multi-wallet architecture.
3. **Automated Token Registration:** Seamlessly integrates token registration with account creation, allowing external issuers to list new assets and bind them to specific pricing oracles.

## 💻 Setup & Testing

This project is optimized for the Hardhat development environment. The included mock contracts ensure the test suite runs entirely locally.

### Prerequisites
* Node.js & npm
* Hardhat

### Installation, Compilation & Testing
```bash
# Install dependencies
npm install

# Compile the smart contracts
npx hardhat compile

#testing
npx hardhat test
