# Epicue Deployment Guide

Epicue supports a unified deployment architecture that allows for seamless transitions between local development and public institutional rollout.

## Deployment Targets

The system identifies two primary deployment targets, switchable via the `EPICUE_DEPLOY_TARGET` environment variable.

### 1. Local (Katana/Devnet)
Professional-grade local simulation for zero-cost parity testing.
- **RPC**: `http://localhost:5050`
- **Cost**: 0 (uses pre-funded accounts)
- **Speed**: Instant finality.

### 2. Public (Starknet Sepolia)
Live testnet environment for institutional verification and integration.
- **RPC**: Variable (Alchemy, Infura, Blast).
- **Cost**: Requires Sepolia ETH.
- **Authentication**: Requires a Starkli/Foundry compatible keystore.

## Deployment Procedure

### Prerequisites
- [Starknet Foundry (sncast)](https://foundry-rs.github.io/starknet-foundry/)
- Python 3.9+ (if using local devnet)

### Unified Execution
The `deployment/deploy.sh` script handles the complexity of environment switching automatically.

```bash
# To deploy locally (Default)
./deployment/deploy.sh

# To deploy to public Sepolia
export EPICUE_DEPLOY_TARGET=public
./deployment/deploy.sh
```

## Portal Configuration

The Epicue Portal identifies the Registry contract via environment variables to maintain institutional security and deployment flexibility.

### Environment Variables
Configure the following in `portal/.env.local`:

- `VITE_REGISTRY_ADDRESS`: The deployed address of the Registry contract (e.g., `0x035fb...`).

### Running the Portal
```bash
cd portal
npm install
npm run dev
```

The portal will be accessible at `http://localhost:3001`.

## Security & Maintenance
- **Environment Isolation**: Local secrets are stored in `deployment/local.env`, while public credentials belong in `deployment/public.env`.
- **Address Privacy**: Avoid hardcoding `CONTRACT_ADDRESS` in the source code; always prefer the `VITE_` prefixed environment variables.
- **Administrative Lock**: Upon deployment, the Registry is immediately locked to the decentralized Governor. All subsequent administrative actions must pass through a governance vote.

## Deployment Topology: Thin-Client vs. Institutional Host

To scale effectively across multiple organizations, Epicue isolates user interface actions from backend node infrastructure:

### 1. Researcher / Reviewer (Thin-Client)
* **Software**: Web browser (accessing the Vite Portal) + Starknet browser wallet (Argent X or Braavos).
* **Requirements**: Zero local installation. Individual researchers/reviewers use their existing browser wallets to sign transactions (e.g., submitting peer reviews, onboarding members, or claiming bounties) without running any node backend locally.
* **Local Wallet Setup**: Run the custom configuration script to retrieve the exact local Devnet network parameters and pre-funded private keys to import into your browser extension:
  ```bash
  ./bin/configure_wallet.sh
  ```

### 2. Institutional Node (Host Infrastructure)
* **Software**: Local IPFS Daemon, Erlang Anomaly Detection Daemon, and Cairo/Stone Prover.
* **Requirements**: Deployed centrally on institutional servers (or shared cloud environments). This backend coordinates connection to the Starknet RPC endpoints, persists large files (like guideline documents) in IPFS, and handles continuous, off-chain anomaly monitoring.
