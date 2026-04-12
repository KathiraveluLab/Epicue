# Epicue

**Equity, Privacy, and Integrity with Cairo in Untrusted Environments**

Epicue is a Starknet-native platform designed to provide a mathematically verifiable, privacy-preserving registry for societal services. 

By leveraging **Cairo 2** and STARK proofs, Epicue ensures that public service data—ranging from healthcare efficacy to industrial carbon traceability—is handled with absolute transparency and integrity without compromising subject privacy.

---

## FATE Architecture

Epicue is built around the **FATE** principles, with core logic and metadata moved on-chain to ensure system-wide trust:

*   **Fairness**: Equitable access through Starknet L2, significantly reducing interaction costs for public reporting.
*   **Accountability**: Every administrative action and record submission is proven mathematically. Includes an on-chain **Compliance Score**.
*   **Transparency**: Modular smart contract logic and on-chain metadata (descriptions, labels, stats) are public and verifiable.
*   **Ethics**: Zero PII (Personally Identifiable Information) stored on-chain. Uses client-side blinded commitments for subject privacy.

## Technical Stack

-   **Smart Contracts**: Cairo 2 (Modular architecture: `metadata`, `governance`, `validation`, `auditor`).
-   **Frontend**: Next.js 14 + Tailwind CSS (Thin-client pattern).
-   **Blockchain**: Starknet (Sepolia/Mainnet).
-   **Provider**: Voyager / Starkscan for verification.

## Repository Structure

```text
├── src/                # Core Cairo Logic (50%+ of codebase)
│   ├── metadata.cairo   # On-chain labels & descriptions
│   ├── governance.cairo # FATE scoring & Authority tracking
│   ├── validation.cairo # Domain-specific business rules
│   ├── auditor.cairo    # Data integrity audit logic
│   └── registry.cairo   # Main entry point & storage
├── tests/              # Comprehensive snforge test suite
├── app/                # Next.js Thin Client
│   └── src/
│       ├── app/        # UI Components & Pages
│       └── lib/        # Starknet hooks & ABI
└── Scarb.toml          # Cairo package management
```

## Getting Started

### Prerequisites
- [Scarb](https://docs.swmansion.com/scarb/) (Cairo package manager)
- [Starknet Foundry (snforge)](https://foundry-rs.github.io/starknet-foundry/)
- Node.js & npm

### Backend (Cairo)
Compile and test the smart contracts:
```bash
scarb build
snforge test
```

### Frontend (Next.js)
Run the development server:
```bash
cd app
npm install
npm run dev
```

---

## Domains
Epicue is currently generalized to support multiple public service sectors:
- Healthcare: Patient access and efficacy reporting.
- Water Quality: Potability alerts and infrastructure feedback.
- Industrial Traceability: Steel mill audits and verifiable carbon footprints.

---
*Built for the future of verifiable public infrastructure.*
