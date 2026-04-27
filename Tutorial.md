# Epicue Institutional Tutorial

This guide provides a walkthrough of the **Epicue BFT Registry** features once you have the local node and portal running.

---

## 1. The EQUISYS Core Concept

Epicue is not just a database; it is a **verifiable institutional agreement engine**. It operates on the principle that in an untrusted internet environment, single-node truth is weak. We rely on **Scientific BFT Resilience** ($n=3f+1$).

### The Triad Roles
- **Validator (The Registry)**: The primary entry point for public service data.
- **Auditor**: Monitors the validator for Byzantine behavior (e.g., inconsistent data).
- **Governor**: The decentralized authority that can change rules or slash malicious institutions.

---

## 2. Setting Up the Simulation

To start with a fully populated institutional environment, run the following seeding scripts:

### A. Populate Records
Submit several verified subject records and institutional history:
```bash
./deployment/populate.sh
```

### B. Seed Governance Proposals
Queue up several institutional change proposals (Add/Remove nodes, Reset Floors):
```bash
./deployment/seed_proposals.sh
```

---

## 3. Using the Institutional Portal (`http://localhost:3001`)

### A. The Registry Dashboard
Monitor the live state of your institutional network:
- **Verified Transmissions**: Every record here is scientifically-proven on Starknet.
- **Institutional Integrity**: A live FATE score (0-100). Starts at `40` (REVIEW_REQUIRED) and grows with activity.
- **BFT Quorum Status (2f + 1)**: Displays the current consensus hardening. The system requires $2f+1$ nodes for a valid quorum.

### B. Managing Governance
Epicue is governed by proposals. Go to the **Governance** tab:
1. **Vote Support**: Select an active proposal (e.g., "Add Health Authority") and cast your supporting vote.
2. **Execute**: Once the dukungan reaches the required threshold, the proposal can be **Executed** to apply the change on-chain.
3. **Automate**: To onboard a specific authority node automatically, run:
   ```bash
   ./deployment/govern.sh <NODE_ADDRESS>
   ```

### C. Auditing Byzantine Faults
Navigate to the **Auditor** tab to test the system's resilience:
- Identify a non-compliant or malicious node address.
- Submit a **Security Signal**.
- **Slashing**: If the Governor validates the fault, the node's reputation is slashed, and the **System Integrity** score adjusts to reflect the risk.

---

## 4. Understanding the Scientific Metrics

Epicue translates raw data into Stark-proven social metrics:

- **FATE Compliance**: Fairness, Accountability, Transparency, and Ethics. This score is calculated dynamically based on record density and node honesty.
- **Sustainability Ledger**: Used for longitudinal tracking of environmental impact data.
- **Digital Reach Index (DRI)**: Tracks the institutional commitment to digital connectivity.

---

## 5. Next Steps
- **Integrate your own schemas**: Modify `src/registry.cairo` to define new institutional data types.
- **Scale to Testnet**: Run `./deployment/deploy.sh` with `EPICUE_DEPLOY_TARGET=public` to move from simulation to Starknet Sepolia.
- **Explore the Tests**: Read `tests/test_bft.cairo` to see how BFT scenarios are mathematically proven.

---
*Strengthening citizens' trust through objective cryptographic guarantees.*
