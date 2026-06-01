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

# 5. Check and Setup IPFS
echo "--- Configuring IPFS ---"
export IPFS_PATH="$(pwd)/.ipfs"

if command -v ipfs &> /dev/null; then
    IPFS_CMD="ipfs"
    echo "Global IPFS installation found: $(ipfs --version)"
elif [ -f "./bin/ipfs" ]; then
    IPFS_CMD="./bin/ipfs"
    echo "Local IPFS binary found: $(./bin/ipfs --version)"
else
    echo "No IPFS installation found. Downloading Kubo (Go-IPFS) locally..."
    mkdir -p bin
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH="arm64"
    fi
    
    KUBO_VERSION="0.29.0"
    TAR_NAME="kubo_v${KUBO_VERSION}_${OS}-${ARCH}.tar.gz"
    DOWNLOAD_URL="https://dist.ipfs.tech/kubo/v${KUBO_VERSION}/${TAR_NAME}"
    
    echo "Downloading from $DOWNLOAD_URL..."
    if command -v curl &> /dev/null; then
        curl -L -o "$TAR_NAME" "$DOWNLOAD_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$TAR_NAME" "$DOWNLOAD_URL"
    else
        echo "Error: Neither curl nor wget is installed. Cannot download IPFS."
        exit 1
    fi
    
    tar -xzf "$TAR_NAME"
    mv kubo/ipfs bin/
    rm -rf kubo "$TAR_NAME"
    IPFS_CMD="./bin/ipfs"
    echo "Local IPFS binary installed successfully."
fi

if [ ! -d ".ipfs" ]; then
    echo "Initializing local IPFS repository..."
    $IPFS_CMD init
fi

echo "--- Building Epicue Framework ---"
scarb build

echo "--- Running Resilience Suite ---"
snforge test

echo "--- Preparing Digital Portal ---"
if [ -d "portal" ]; then
    cd portal
    npm install
    cd ..
fi

echo "--- Setup Complete ---"
echo "The environment is ready. To run the local stack:"
echo "Run: './run_local.sh'"

