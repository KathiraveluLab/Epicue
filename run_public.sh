#!/bin/bash

# Epicue Public Deployment Orchestrator
# Connects to a public Starknet network (like Sepolia), starting the ZK Coprocessor daemon and the portal.

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

# Function to clean up background processes on exit
cleanup() {
    echo ""
    echo "--- Stopping Epicue Public Environment ---"
    echo "[*] Terminating ZK Coprocessor Daemon..."
    kill $DAEMON_PID 2>/dev/null || true
    exit 0
}

# Trap exit signals to run cleanup
trap cleanup INT TERM EXIT

# 2. Start ZK Coprocessor Daemon in the background
echo "[*] Starting ZK Coprocessor Daemon..."
./run_daemon.sh > daemon.log 2>&1 &
DAEMON_PID=$!

# 3. Run Portal in the foreground
echo "[*] Launching Portal Client..."
./run_portal.sh
