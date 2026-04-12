#!/bin/bash

# Epicue Local Devnet Setup Script
# Initializes a project-local Python virtual environment and installs starknet-devnet.

set -e

echo "--- Initializing Local Python Environment ---"
python3 -m venv .venv
source .venv/bin/activate

echo "--- Installing Starknet Devnet ---"
# We use a specific version known to work with Starknet Foundry 0.59.0
pip install --upgrade pip
pip install starknet-devnet

echo "--- Devnet Setup Complete ---"
echo "To start the node: 'source .venv/bin/activate && starknet-devnet --port 5050'"
