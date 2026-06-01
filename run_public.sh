#!/bin/bash

# Epicue Public Deployment Orchestrator
# Connects to a public Starknet network (like Sepolia), starting the ZK Coprocessor daemon and the portal.

export IPFS_PATH="$(pwd)/.ipfs"

echo "--- Booting Epicue Public Environment ---"

# 1. Verify environment configuration
if [ ! -f "deployment/.env" ]; then
    echo "Error: deployment/.env not found."
    echo "Please copy deployment/sepolia.env.template to deployment/.env and populate it."
    exit 1
fi

if [ ! -f "portal/.env.local" ]; then
    echo "Error: portal/.env.local not found."
    echo "This means the contract hasn't been deployed yet, or configuration is missing."
    echo "Please run: ./deployment/deploy_sepolia.sh first to deploy and set up portal config."
    exit 1
fi

# 2. Start Local IPFS Daemon in the background
echo "[*] Starting IPFS Daemon..."
if [ -f "./bin/ipfs" ]; then
    IPFS_CMD="./bin/ipfs"
elif command -v ipfs &> /dev/null; then
    IPFS_CMD="ipfs"
else
    echo "Error: IPFS is not installed. Please run ./setup.sh first."
    exit 1
fi
$IPFS_CMD daemon > ipfs.log 2>&1 &
IPFS_PID=$!

# Function to clean up background processes on exit
cleanup() {
    echo ""
    echo "--- Stopping Epicue Public Environment ---"
    echo "[*] Terminating ZK Coprocessor Daemon..."
    kill $DAEMON_PID 2>/dev/null || true
    echo "[*] Terminating IPFS Daemon..."
    kill $IPFS_PID 2>/dev/null || true
    exit 0
}

# Trap exit signals to run cleanup
trap cleanup INT TERM EXIT

# 3. Start ZK Coprocessor Daemon in the background
echo "[*] Starting ZK Coprocessor Daemon..."
./run_daemon.sh > daemon.log 2>&1 &
DAEMON_PID=$!

# 4. Run Portal in the foreground
echo "[*] Launching Portal Client..."
./run_portal.sh
