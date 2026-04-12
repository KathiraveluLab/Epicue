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

- `NEXT_PUBLIC_REGISTRY_ADDRESS`: The deployed address of the Registry contract (e.g., `0x035fb...`).

### Running the Portal
```bash
cd portal
npm install
npm run dev
```

The portal will be accessible at `http://localhost:3000`.

## Security & Maintenance
- **Environment Isolation**: Local secrets are stored in `deployment/local.env`, while public credentials belong in `deployment/public.env`.
- **Address Privacy**: Avoid hardcoding `CONTRACT_ADDRESS` in the source code; always prefer the `NEXT_PUBLIC_` prefixed environment variables.
- **Administrative Lock**: Upon deployment, the Registry is immediately locked to the decentralized Governor. All subsequent administrative actions must pass through a governance vote.

---
*For a detailed walkthrough of the BFT features, see [walkthrough.md](file:///home/pradeeban/.gemini/antigravity/brain/a61fd118-f904-4455-a32c-44883f0b530f/walkthrough.md).*
