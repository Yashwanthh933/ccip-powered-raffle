# 🎲 CCIP-Powered Raffle

<div align="center">

![Solidity](https://img.shields.io/badge/Solidity-0.8.x-363636?style=for-the-badge&logo=solidity)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?style=for-the-badge)
![Chainlink](https://img.shields.io/badge/Powered%20by-Chainlink-375BD2?style=for-the-badge&logo=chainlink)
![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A trustless, cross-chain raffle protocol powered by Chainlink VRF, Automation, and CCIP.**

Users enter by depositing a fixed amount. Every 7 days, a provably random winner is selected and their prize is automatically transferred to any supported chain of their choice.

</div>

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Build & Test](#build--test)
- [Deployment](#deployment)
- [Post-Deployment Setup](#post-deployment-setup)
- [Testnet Reference](#testnet-reference)
- [Roadmap](#roadmap)
- [License](#license)

---

## Overview

CCIP-Powered Raffle is a decentralized lottery system with no admin control over winner selection. The protocol relies entirely on Chainlink's infrastructure for fairness, automation, and cross-chain interoperability:

- **No trusted randomness** — Chainlink VRF v2.5 ensures winner selection cannot be manipulated
- **No manual triggers** — Chainlink Automation calls the draw every 7 days automatically
- **No chain restrictions** — Winners receive their prize on any CCIP-supported chain

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Flow                           │
└─────────────────────────────────────────────────────────────┘

  User ──► enterRaffle()  ──► Raffle Pool (locked)
                                      │
                              [7 days elapse]
                                      │
                                      ▼
                         Chainlink Automation
                         calls checkUpkeep()
                         ✓ time passed
                         ✓ players exist
                         ✓ raffle is OPEN
                                      │
                                      ▼
                         performUpkeep() triggered
                         → VRF randomness requested
                                      │
                                      ▼
                         Chainlink VRF fulfillRandomWords()
                         → winner(s) selected on-chain
                                      │
                                      ▼
                         Chainlink CCIP transfers prize
                         → winner's chosen destination chain
```

---

## Tech Stack

| Protocol / Tool | Role |
|---|---|
| [Solidity](https://soliditylang.org/) | Smart contract language |
| [Foundry](https://getfoundry.sh/) | Build, test, and deploy framework |
| [Chainlink VRF v2.5](https://docs.chain.link/vrf) | Verifiable random winner selection |
| [Chainlink Automation](https://docs.chain.link/chainlink-automation) | Trustless 7-day draw trigger |
| [Chainlink CCIP](https://docs.chain.link/ccip) | Cross-chain prize token transfer |
| [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) | Standard contract utilities |
| [chainlink-local](https://github.com/smartcontractkit/chainlink-local) | Local CCIP simulation for testing |
| [foundry-devops](https://github.com/Cyfrin/foundry-devops) | Deployment helpers |

---

## Project Structure

```
ccip-powered-raffle/
├── src/
│   ├── Raffle.sol              # Core raffle logic
│   └── ...                     # CCIP sender / receiver contracts
├── script/
│   ├── DeployRaffle.s.sol      # Deployment script
│   ├── HelperConfig.s.sol      # Per-network configuration
│   └── Interactions.s.sol      # Post-deploy interaction scripts
├── test/
│   ├── unit/                   # Unit tests
│   └── integration/            # Fork & integration tests
├── lib/                        # Git submodule dependencies
│   ├── forge-std
│   ├── openzeppelin-contracts
│   ├── chainlink
│   ├── ccip
│   ├── chainlink-local
│   └── foundry-devops
├── .github/
│   └── workflows/              # CI pipeline
├── foundry.toml
├── .gitmodules
└── .env.example
```

---

## Prerequisites

Before you begin, ensure you have the following:

- [Git](https://git-scm.com/)
- [Foundry](https://getfoundry.sh/) — install via:
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- A funded testnet wallet (ETH + LINK on Sepolia)
- An RPC URL (e.g. from [Alchemy](https://alchemy.com) or [Infura](https://infura.io))
- A funded [Chainlink VRF Subscription](https://vrf.chain.link/)
- A registered [Chainlink Automation Upkeep](https://automation.chain.link/)

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Yashwanthh933/ccip-powered-raffle
cd ccip-powered-raffle
```

### 2. Install dependencies

```bash
git submodule update --init --recursive
```

### 3. Set up environment variables

```bash
cp .env.example .env
```

Fill in your values (see [Environment Variables](#environment-variables) below), then load them:

```bash
source .env
```

---

## Environment Variables

Create a `.env` file in the root with the following:

```env
# ── Wallet ──────────────────────────────────────
PRIVATE_KEY=0x...

# ── RPC URLs ─────────────────────────────────────
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<your_key>

# ── Verification ─────────────────────────────────
ETHERSCAN_API_KEY=<your_etherscan_key>

# ── Chainlink VRF ────────────────────────────────
VRF_SUBSCRIPTION_ID=<your_subscription_id>

# ── Chainlink CCIP (Sepolia) ──────────────────────
CCIP_ROUTER=0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
LINK_TOKEN=0x779877A7B0D9E8603169DdbD7836e478b4624789
```

> ⚠️ Never commit your `.env` file. It is already in `.gitignore`.

---

## Build & Test

### Compile contracts

```bash
forge build
```

### Run all tests

```bash
forge test
```

### Run with logs and traces

```bash
forge test -vvv
```

### Run a specific test file

```bash
forge test --match-path test/unit/RaffleTest.t.sol -vvv
```

### Check coverage

```bash
forge coverage
```

### Format code

```bash
forge fmt
```

---

## Deployment

### Deploy to Sepolia testnet

```bash
forge script script/DeployRaffle.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Deploy and verify on Etherscan

```bash
forge script script/DeployRaffle.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Run on local Anvil node

```bash
# Terminal 1
anvil

# Terminal 2
forge script script/DeployRaffle.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key $PRIVATE_KEY \
  --broadcast
```

---

## Post-Deployment Setup

After deploying the contract, complete these three steps to activate the full protocol:

### 1. Add contract as VRF Consumer

- Go to [vrf.chain.link](https://vrf.chain.link/)
- Select your subscription
- Click **Add Consumer** and paste your deployed contract address
- Ensure the subscription is funded with LINK

### 2. Register Automation Upkeep

- Go to [automation.chain.link](https://automation.chain.link/)
- Click **Register New Upkeep** → select **Custom Logic**
- Set your deployed contract as the target address
- Fund the upkeep with LINK

### 3. Confirm CCIP destination chain support

- Check supported chains and tokens at [CCIP Supported Networks](https://docs.chain.link/ccip/supported-networks)
- Ensure the destination chain selector is configured in `HelperConfig.s.sol`

