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

## 2. Walkthrough: Registering a Public Service

Once the portal is open at `http://localhost:3001`, follow these steps:

### A. Monitor System Integrity
1. Navigate to the **Auditor** tab.
2. View the **System Integrity** score (e.g., STABLE/98).
3. This dashboard monitors scientific telemetry for Byzantine faults in real-time.

### B. View Verified Transmissions
1. Go to the **Registry** tab.
2. Observe the **Verified Transmissions** counter. Each transmission represents a scientifically-proven record on Starknet.
3. Scroll down to see the **Latest Transmissions** list.

### C. Populate Test Data
If your registry is empty, you can seed it with simulated institutional data:
1. In your terminal, run:
   ```bash
   ./deployment/populate.sh
   ```
2. Refresh the portal to see the new records appearing in real-time.

---

## 3. Simulating Byzantine Resilience

Epicue is designed to survive malicious environments. You can observe the resilience in the **Auditor Integrity Monitor** tab.

### Detecting a Fault
In a production environment, different nodes might report different data. In our local simulation:
1. The **Auditor Dashboard** tracks "Integrity Deviations."
2. If a record is submitted that violates the **FATE Compliance Score** (Fairness, Accountability, Transparency, Ethics), a "Byzantine Flag" is raised.
3. Observe how the **Institutional Reputation** of the submitter decays immediately upon a flagged fault.

### Graded Slashing
If the fault is categorized as **Critical**, the Governor may initiate a slashing event.
- **Minor Faults**: Result in a temporary suspension of voting power.
- **Critical Faults**: Result in the architectural revocation of authority.

---

## 4. Understanding the Metrics

Epicue translates raw data into Stark-proven social metrics:

- **Digital Reach Index (DRI)**: 
    - *Scenario*: Record a service that provides digital connectivity to a rural area.
    - *Result*: The DRI score will rise, reflecting higher institutional social equity.
- **Sustainability Ledger**: 
    - *Scenario*: Record manufacturing data with high environmental impact.
    - *Result*: The Green Stature Index will track this longitudinal decay, and it will be visible in the analytics charts.

---

## 5. Participating in Governance

The **EQUISYS Governor** ensures that no single entity can unilaterally change the rules.
1. Navigate to the **Governance** tab.
2. View active **Threshold Modification** proposals.
3. As the `Initial Authority` (your local account), you can cast votes on these proposals.
4. Once a proposal passes the $2f+1$ quorum, the Registry configuration updates automatically on-chain.

---

## Next Steps
- **Integrate your own schemas**: Modify `src/core/schema.cairo` to define new public service data types.
- **Scale to Testnet**: Run `./deployment/deploy.sh` with `EPICUE_DEPLOY_TARGET=public` to move from simulation to the real Starknet Sepolia network.
- **Explore the Tests**: Read `tests/test_bft.cairo` to see how these BFT scenarios are mathematically proven.

---
*Strengthening citizens' trust through objective cryptographic guarantees.*
