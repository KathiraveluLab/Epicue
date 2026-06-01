#!/bin/bash

export IPFS_PATH="$(pwd)/.ipfs"

# 1. Start Local IPFS Daemon in the background
echo "[*] Starting IPFS Daemon..."
if [ -f "./bin/ipfs" ]; then
    IPFS_CMD="./bin/ipfs"
elif command -v ipfs &> /dev/null; then
    IPFS_CMD="ipfs"
else
    echo "Error: IPFS is not installed. Please run ./scripts/setup.sh first."
    exit 1
fi
$IPFS_CMD daemon > ipfs.log 2>&1 &
IPFS_PID=$!

# 2. Start Local Devnet in the background
echo "[*] Starting Starknet Devnet..."
./scripts/run_devnet.sh > devnet.log 2>&1 &
DEVNET_PID=$!

# Function to clean up background processes on exit
cleanup() {
    echo ""
    echo "--- Stopping Epicue Local Environment ---"
    echo "[*] Terminating ZK Coprocessor Daemon..."
    kill $DAEMON_PID 2>/dev/null || true
    echo "[*] Terminating Starknet Devnet..."
    kill $DEVNET_PID 2>/dev/null || true
    echo "[*] Terminating IPFS Daemon..."
    kill $IPFS_PID 2>/dev/null || true
    exit 0
}

# Trap exit signals to run cleanup
trap cleanup INT TERM EXIT

# Wait for devnet to start
echo "[*] Waiting for Devnet to initialize..."
for i in {1..10}; do
    if curl -s http://localhost:5050/is_alive > /dev/null; then
        echo "[+] Devnet is online."
        break
    fi
    if [ $i -eq 10 ]; then
        echo "Error: Devnet failed to start."
        exit 1
    fi
    sleep 1
done

# 2. Deploy Contract
echo "[*] Deploying Registry Contract..."
./deployment/deploy.sh

# 3. Populate Test Data
echo "[*] Populating Registry with test records..."
./deployment/populate.sh

# 4. Start ZK Coprocessor Daemon in the background
echo "[*] Starting ZK Coprocessor Daemon..."
./scripts/run_daemon.sh > daemon.log 2>&1 &
DAEMON_PID=$!

# 5. Run Portal in the foreground
echo "[*] Launching Portal Client..."
./scripts/run_portal.sh
