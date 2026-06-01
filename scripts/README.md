# Epicue Core Scripts Directory

This directory contains shell scripts to configure, run, and interact with the local and public environments of the Epicue framework. All scripts are designed to be run from the **workspace root** (e.g., `./scripts/setup.sh`).

---

## Script Index

### 1. `setup.sh`
* **Purpose**: Performs system-wide environment preparation and initialization.
* **Actions**:
  * Detects and checks local toolchain versions (`scarb`, `snforge`, `sncast`).
  * Creates and initializes a local Python virtual environment (`.venv`).
  * Downloads, installs, and initializes an isolated local IPFS/Kubo binary inside `.ipfs/`.
  * Compiles all Cairo packages and executes the `snforge` Byzantine resilience tests.
  * Installs Node.js dependencies for the front-end web portal.

### 2. `run_local.sh`
* **Purpose**: Orchestrates and launches the complete local development stack.
* **Actions**:
  * Starts the local IPFS daemon in the background.
  * Starts the local Starknet Devnet emulator on port `5050` (using deterministic seed `0`).
  * Automatically compiles and deploys the Epicue Registry contract.
  * Populates the registry with simulated SDG telemetry (FATE scores, green stature index, etc.).
  * Compiles and runs the Erlang anomaly auditor daemon.
  * Launches the front-end Vite Portal in the foreground at `http://localhost:3001`.

### 3. `run_public.sh`
* **Purpose**: Orchestrates connecting the portal and off-chain daemon to a public Starknet network.
* **Actions**:
  * Checks for public credentials/deployment files (`deployment/.env` and `portal/.env.local`).
  * Launches the local IPFS daemon.
  * Launches the Erlang ZK Coprocessor auditor daemon connected to the target public Starknet RPC.
  * Boots the front-end Vite Portal configured to read and write to the deployed public contracts.

### 4. `run_devnet.sh`
* **Purpose**: Boots the local Starknet Devnet node emulator on `http://localhost:5050`.

### 5. `run_daemon.sh`
* **Purpose**: Compiles the Erlang source files (`daemon/auditor.erl`) and starts the off-chain ZK Coprocessor daemon.

### 6. `run_portal.sh`
* **Purpose**: Installs portal dependencies (if missing) and launches the Vite client server in the foreground.

---
*For more information about deployments and wallets, see [docs/Deployment.md](../docs/Deployment.md).*
