# Epicue: Decentralized Multidisciplinary Governance Framework for FATE in Service Policies.

**Equity, Privacy, and Integrity with Cairo in Untrusted Environments**

Epicue is a Starknet-native framework designed to resolve the trust-accountability dilemma in societal service registries operating across untrusted networks. By leveraging Cairo smart contracts and off-chain Layer 2 scalability, Epicue enforces the **FATE** (Fairness, Accountability, Transparency, Ethics) principles directly within the execution layer. Rather than relying on centralized trust assumptions or expensive Layer 1 consensus, Epicue introduces an integrated, on-chain architectural engine—**the Triad**—to govern, validate, and audit public service records with mathematical finality.

---

## The Core Scientific Innovations

Epicue replaces conventional, static database registries with a dynamic cryptosystem built around three primary design pillars:

### 1. The Epicue Triad (Validator, Auditor, Governor)
The registry's integrity is maintained by a collaborative set of modular pillars operating as a unified on-chain state machine:
*   **The Validator (Integrity):** Performs synchronous geofencing and semantic validation directly inside the Cairo Virtual Machine. This ensures that every submitted record complies with localized spatial boundaries (e.g., municipal coordinates) and domain schemas without relying on external, vulnerable oracle networks.
*   **The Auditor (Transparency):** Asynchronously monitors submitter behavior using differential analysis of the trust gradient ($\nabla S$). If a node's reputation decays rapidly or deviates from BFT expectations, the Auditor flags the node as *Failing* or *Byzantine*.
*   **The Governor (Accountability):** Executes decentralized governance. When Byzantine behavior is proven, the Governor applies graded slashing rules (minor, major, or total revocation of authority) and dynamically adjusts the BFT quorum thresholds ($2f+1$) to safeguard the registry's liveness.

### 2. Spatiotemporal Trust Manifolds
Reputation in Epicue is modeled as a continuous spatiotemporal manifold rather than a static score:
*   **Spatial Dimension:** A node’s trust expands across multiple service domains (Health, Education, Agriculture) only when verified by consensus.
*   **Temporal Dimension:** Honest history increases a node's trust score, while inactivity triggers a mathematical decay.
*   **Safety Floor:** A hardcoded reputation floor ($R_{floor} = 40$) ensures that recovering nodes are kept under review and prevents compromised nodes from regaining full consensus rights without governance override.

### 3. Hybrid STARK Coprocessing (Erlang + Cairo)
To keep on-chain execution costs low while supporting heavy auditing algorithms:
*   **Off-Chain Analysis:** An Erlang-based coprocessor daemon (`daemon/auditor.erl`) continuously polls the Starknet JSON-RPC node. It performs statistical anomaly detection and runs Cairo-based auditing scripts on historical ledger data.
*   **Proof Generation:** When divergence is detected, the daemon executes a local STARK prover (e.g., the Stone Prover) to generate a cryptographic proof of Byzantine behavior.
*   **Cheap On-Chain Verification:** The daemon submits the STARK proof to the registry's `claim_security_bounty` endpoint. The on-chain Triad modules verify the proof for a fraction of the cost of full re-execution and distribute a bounty reward to the auditor.

### 4. Layer 2 Paymaster & Sponsored Transactions
To insulate municipal operators and citizens from Layer 1 gas volatility, Epicue uses Starknet's native Account Abstraction:
*   **Fee Delegation:** Sponsors fund a centralized on-chain Paymaster contract and whitelist users. When a whitelisted user submits a record, the validator hook handles gas payment using the sponsor's pool.
*   **99.9% Cost Reduction:** By utilizing Starknet post-Dencun (EIP-4844 data blobs), a mid-sized municipality processing 15,000 transactions/month incurs less than **$300 USD/month** in L2 gas fees, compared to over **$30,000 USD/month** on an EVM Layer 1.

---

## FATE Alignment & UN SDGs

Epicue maps on-chain cryptographic assertions directly to the United Nations Sustainable Development Goals (SDGs):

| Index Metric | SDG Target | Cairo Mechanism |
| :--- | :--- | :--- |
| **Digital Reach Index (DRI)** | **SDG 10 (Reduced Inequalities)** | Tracks equity of public service coverage and access across geographic zones. |
| **Green Stature Index** | **SDG 12 (Responsible Consumption)** | Monitors industrial emission thresholds and publishes verified compliance logs. |
| **FATE Compliance Score** | **SDG 16 (Peace, Justice, & Strong Institutions)** | Dynamically calculated score mapping registry health, node honesty, and slashing events. |

---

## Package Hierarchy

```text
├── src/                # Cairo Core Smart Contracts (Starknet)
│   ├── core/           # Core registries, paymaster, access control, and types
│   ├── triad/          # The Triad Engine (Validator, Auditor, Governor)
│   ├── research/       # Scientific consensus, BFT review, and methodologies
│   ├── social/         # Equity indices, reputation dynamics, and bounties
│   └── metrics/        # Sustainability ledgers and UN SDG index calculation
├── daemon/             # Erlang Coprocessor (Off-chain STARK Prover Host)
├── scripts/            # Orchestration Shell Scripts (Setup, Devnet, Portal)
├── tests/              # Byzantine Resilience & Performance Test Suite
├── portal/             # React/Vite Dashboard Frontend
└── deployment/         # Environment files and contract deployment scripts
```

---

## Getting Started

### 1. Project Setup
Initialize the development environment and local IPFS repository:
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Run Local Development Stack
Spin up the Starknet local devnet, IPFS daemon, contract compiler, coprocessor, and the Web Portal UI with a single command:
```bash
./scripts/run_local.sh
```
*The portal will be available at `http://localhost:3001`.*

### 3. Connect to Public Networks (Sepolia Testnet)
Configure environment variables and deploy:
```bash
cp deployment/sepolia.env.template deployment/.env
# Edit deployment/.env with your RPC URL, account address, and private key
./deployment/deploy_sepolia.sh
./scripts/run_public.sh
```

---

## Manual Walkthrough & Verification

For a complete manual verification of the Epicue engine, see the following guides:
*   **[Step-by-Step Tutorial Guide](docs/Tutorial.md):** Learn how to setup local wallets, submit records, create governance proposals, slash Byzantine nodes, and test the sponsored transactions simulator.
*   **[Verifiable Use Cases](docs/Usecases.md):** Deep-dive into the water registry, industrial green stature tracker, and educational reach records.
*   **[Deployment Architecture Guide](docs/Deployment.md):** Detailed walkthrough of the Layer 2 smart contract deployment and network configuration.
