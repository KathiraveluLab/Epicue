#!/bin/bash

# Epicue Project Setup Script
# Orchestrates prerequisites and environment configurations.

set -e

echo "--- Epicue Setup ---"

# 1. Check for Scarb
if ! command -v scarb &> /dev/null
then
    echo "Error: Scarb is not installed. Please install it from https://docs.swmansion.com/scarb/"
    exit 1
fi
echo "Scarb found: $(scarb --version | head -n 1)"

# 2. Check for Starknet Foundry (snforge and sncast)
if ! command -v snforge &> /dev/null
then
    echo "Error: snforge is not installed. Please install it from https://foundry-rs.github.io/starknet-foundry/"
    exit 1
fi
echo "snforge found: $(snforge --version)"

if ! command -v sncast &> /dev/null
then
    echo "Error: sncast is not installed. Please install it from https://foundry-rs.github.io/starknet-foundry/"
    exit 1
fi
echo "sncast found: $(sncast --version)"

# 3. Setup Python Virtual Environment
if [ ! -d ".venv" ]; then
    echo "--- Initializing Local Python Environment ---"
    python3 -m venv .venv
fi

# 4. Handle Devnet Binary
if [ -f "deployment/starknet-devnet" ]; then
    echo "Using bundled starknet-devnet binary."
    chmod +x deployment/starknet-devnet
else
    echo "Warning: deployment/starknet-devnet binary not found."
    echo "You may need to download it or install it via cargo."
fi

# 4. Handle Configuration
echo "--- Configuring Environment ---"
if [ -f "deployment/.env" ]; then
    echo "deployment/.env already exists."
else
    if [ -f "deployment/sepolia.env.template" ]; then
        cp deployment/sepolia.env.template deployment/.env
        echo "Created deployment/.env from template."
    fi
fi

echo "--- Building Epicue Framework ---"
scarb build

echo "--- Running Resilience Suite ---"
snforge test

echo "--- Setup Complete ---"
echo "The environment is ready. To deploy locally:"
echo "1. In one terminal, run: './run_devnet.sh'"
echo "2. In another terminal, run: './deployment/deploy.sh'"
