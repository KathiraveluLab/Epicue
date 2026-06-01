# Epicue

**Equity, Privacy, and Integrity with Cairo in Untrusted Environments**

Epicue is a Starknet-native framework designed to provide a mathematically verifiable, Byzantine-fault-tolerant registry for societal services. It ensures that public service data is handled with absolute transparency and integrity, even in the presence of malicious nodes in untrusted internet environments.

---

## Byzantine Fault Tolerance (BFT) & Governance
Epicue is engineered for the untrusted Internet. Unlike typical centralized registries, Epicue incorporates **Scientific BFT Resilience** ($n=3f+1$):
- **2f+1 Scientific Quorum**: New methodologies and research protocols require cryptographically-verified endorsements from a $2f+1$ institutional majority.
- **Decentralized Governance Locks**: All administrative actions (authority management, reputation floors) are strictly locked behind the Epicue Governor. Modifications are only executable via successful voting proposals.
- **Graded Byzantine Slashing**: Institutional penalties are categorized by severity (Minor, Major, Critical). Critical faults result in architectural revocation of authority.
- **Security Bounties**: A built-in **Bounty Credit** system incentivizes specialized auditors to detect and flag Byzantine faults.

## Package Hierarchy
The codebase is structured into logical layers to facilitate inter-institutional scale-up:

```text
├── src/                # Cairo Core Implementation
│   ├── core/           # Fundamental Logic (Access, Metadata, Types)
│   ├── triad/          # The Epicue Triad (Validator, Auditor, Governor)
│   ├── research/       # Scientific Productivity (BFT Peer Review, Methodology)
│   ├── social/         # Equity & Inclusion (DRI, Reputation, Bounty)
│   └── metrics/        # High-Level Analytics (Sustainability Ledger)
├── daemon/             # Erlang Coprocessor (Off-chain STARK Prover Host)
├── tests/              # Byzantine Resilience & Performance Tests
└── portal/             # Vite Client
```

## Institutional Portal

The Epicue Registry Portal provides a high-fidelity interface for institutional stakeholders to interact with the Starknet-native BFT registry.

![Registry Dashboard](portal/docs/screenshots/registry_home.png)

![Governance Interface](portal/docs/screenshots/governance_tab.png)

![Auditor Integrity Monitor](portal/docs/screenshots/auditor_tab.png)

## Scientific Metrics & SDGs
Epicue translates UN Sustainable Development Goals (SDGs) into STARK-proven metrics:
- **Digital Reach Index (DRI)**: Measures the social equity of public services (SDG 10).
- **Green Stature Index**: Tracks longitudinal sustainability in manufacturing sectors like Steel Mills (SDG 12).
- **FATE Compliance Score**: A real-time measure of institutional accountability (SDG 16).

## Getting Started

### Project Setup
Initialize the environment, install dependencies, and run initial verification. The setup script will automatically detect your OS/architecture, download the Kubo (IPFS) binary locally, and initialize an isolated IPFS repository at `.ipfs/` in the workspace:
```bash
chmod +x setup.sh
./setup.sh
```

### Local Development
To run the entire local development stack (Starknet Devnet, local IPFS Daemon, contract deployment, test data population, the ZK Coprocessor daemon, and the Web Portal) with a single command:
```bash
./run_local.sh
```
The portal will be available at `http://localhost:3001`.

This script starts all required background processes (including the isolated IPFS node) and launches the portal. To shut down all services cleanly, simply press `Ctrl+C` in the terminal window.

### Public Network / Decoupled Deployment
To connect the stack to a public Starknet network (e.g. Sepolia testnet or Mainnet):
1. **Configure and deploy**:
   ```bash
   cp deployment/sepolia.env.template deployment/.env
   # Edit deployment/.env with your RPC URL, account address, and keystore path
   ./deployment/deploy_sepolia.sh
   ```
2. **Start the portal and daemon**:
   ```bash
   ./run_public.sh
   ```
   The portal will be available at `http://localhost:3001` and is connected to the public Starknet network contract. To shut down cleanly, simply press `Ctrl+C`.

### Detailed Walkthrough
See the [Tutorial Guide](docs/Tutorial.md) for a step-by-step walkthrough of institutional features.

### Verifiable Use Cases
See the [Verifiable Use Cases Guide](docs/Usecases.md) for a detailed technical description of the domain-specific data structures and FATE alignment matrices.

### Evaluation & Datasets
For the raw datasets and `snforge` simulation logs utilized for the manuscript evaluation, please see the [Evaluation Datasets](data/README.md). All artifacts contained within were derived directly from local test executions.

### Deployment

Epicue supports a unified deployment architecture for both local and public targets. See the [Deployment Guide](docs/Deployment.md) or the [Deployment Architecture](docs/README.md) for a detailed graphical overview and instructions.

1. **Configure Environment**: Choose your target.
   ```bash
   cp deployment/sepolia.env.template deployment/.env
   # Edit deployment/.env with your secrets
   ```

2. **Run Deployment Script**: Ensure your account is funded and your keystore is accessible.
   ```bash
   chmod +x deployment/deploy_sepolia.sh
   ./deployment/deploy_sepolia.sh
   ```

## Security, Byzantine Resilience, & ZK Coprocessors
The framework enforces a rigorous $n=3f+1$ Byzantine Fault Tolerance model. Security audits are driven by a hybrid **ZK Coprocessor Architecture**:
- **Off-Chain Proving**: An Erlang-based daemon (`daemon/auditor.erl`) continuously polls the Starknet RPC, running heavy statistical analysis on institutional records to detect anomalies. Upon detection, it triggers a local Cairo program to generate a cryptographic STARK proof.
- **On-Chain Verification**: The daemon submits this proof via the `claim_security_bounty` transaction to the Epicue Registry. The on-chain Triad modules cheaply verify the STARK proof and apply the appropriate institutional slashing.
- **Manual Fallback**: Institutional watchdogs can bypass the automated daemon and manually trigger the slashing sequence via the Web Portal UI by providing the malicious address, the empirically calculated **Deviation \%**, the **Total Reviews** sample size, and the corresponding **Off-chain STARK Proof Hash** (generated by downloading public ledger history, feeding it into a Cairo auditing algorithm, and executing a local STARK prover such as the Stone Prover).

---
*Strengthening citizens' trust through objective cryptographic guarantees.*
