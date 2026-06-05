# Epicue Deployment Guide

Epicue supports a unified deployment architecture that allows for seamless transitions between local development and public institutional rollout.

## Deployment Targets

The system supports four distinct deployment topologies to accommodate different institutional requirements, gas cost policies, and trust assumptions.

### 1. Local Simulation (Katana/Devnet)
Professional-grade local simulation for zero-cost parity testing during development.
- **RPC**: `http://localhost:5050`
- **Gas Cost**: None (uses pre-funded developer accounts).
- **Speed**: Instant block finality on-demand.
- **Target Value**: `local` (default).

### 2. Federated Devnet (Katana)
A persistent, private, zero-gas consortium network hosted across secure institutional servers (typically behind a shared VPN).
- **RPC**: Private domain (e.g., `http://epicue-node.consortium.org:5050`).
- **Gas Cost**: None (uses pre-funded institutional keys managed via ACLs).
- **Speed**: Instant or configured periodic block finality.
- **Target Value**: Custom RPC endpoint in `local.env`.

### 3. Private Madara Appchain (Production-grade L3/L2)
An enterprise-grade, customizable Starknet-compatible appchain sequencer built on the Substrate framework.
- **RPC**: Custom sequencer endpoint.
- **Gas Cost**: Configurable to zero gas, or uses a custom free-to-mint utility token to mitigate spam.
- **Data Availability**: Uses a Data Availability Committee (DAC) or private DA (e.g., Celestia) to eliminate public L1 blob costs.
- **Target Value**: Custom RPC configured in `public.env`.

### 4. Public Starknet (Sepolia Testnet / Mainnet)
The live public Starknet network, utilizing on-chain Paymasters to achieve gasless user interactions via institutional sponsorship.
- **RPC**: Public node providers (Alchemy, Infura, Blast).
- **Gas Cost**: Paid in ETH or STRK on-chain (delegated to the Paymaster contract pool).
- **Authentication**: Requires a Starkli/Foundry compatible secure keystore.
- **Target Value**: `public`.

## Deployment Procedure

### Prerequisites
- [Starknet Foundry (sncast)](https://foundry-rs.github.io/starknet-foundry/)
- Python 3.9+ (if using local devnet)

### Unified Execution
The `deployment/deploy.sh` script handles the complexity of environment switching automatically. Ensure you copy and configure the correct env template before running:

```bash
# 1. To deploy locally (Default local simulation)
./deployment/deploy.sh

# 2. To deploy to a Federated Devnet (Consortium Network)
cp deployment/federated.env.template deployment/federated.env
# (Edit deployment/federated.env with your consortium RPC and account details)
export EPICUE_DEPLOY_TARGET=federated
./deployment/deploy.sh

# 3. To deploy to a Madara Appchain
cp deployment/madara.env.template deployment/madara.env
# (Edit deployment/madara.env with your Madara sequencer RPC and account details)
export EPICUE_DEPLOY_TARGET=madara
./deployment/deploy.sh

# 4. To deploy to Public Starknet (Sepolia/Mainnet)
cp deployment/sepolia.env.template deployment/public.env
# (Edit deployment/public.env with your public RPC URL and keystore details)
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
