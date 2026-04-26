#!/bin/bash

# Epicue Devnet Runner
# Starts a local Starknet Devnet node.

set -e

# Path to the virtual environment created by setup.sh
VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Virtual environment not found. Please run ./setup.sh first."
    exit 1
fi

echo "--- Starting Starknet Devnet ---"

# Use the bundled binary if available, otherwise fallback to system path
if [ -f "deployment/starknet-devnet" ]; then
    DEVNET_BIN="./deployment/starknet-devnet"
elif command -v starknet-devnet &> /dev/null; then
    DEVNET_BIN="starknet-devnet"
else
    echo "Error: starknet-devnet not found in deployment/ or PATH."
    echo "Please run ./setup.sh or install it manually."
    exit 1
fi

echo "Using: $DEVNET_BIN"
echo "Node will be available at http://localhost:5050"
echo "Press Ctrl+C to stop."
echo "------------------------------------------------"

$DEVNET_BIN --port 5050 --seed 0 --chain-id devnet
