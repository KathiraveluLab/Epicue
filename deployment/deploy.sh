#!/bin/bash

# Epicue Unified Deployment Script (EQUISYS Architecture)
# Supports Local (Devnet) and Public (Sepolia) targets.

set -e

# Default target if not specified
TARGET=${EPICUE_DEPLOY_TARGET:-local}

echo "--- Initializing Deployment: Target=$TARGET ---"

# Load environment
if [ "$TARGET" == "local" ]; then
    source deployment/local.env
    # Ensure local account is imported into sncast
    echo "Importing local account..."
    # Global flags like --accounts-file MUST come before the subcommand
    sncast --accounts-file deployment/accounts.json account import \
        --url "$STARKNET_RPC" \
        --name local \
        --address "$STARKNET_ACCOUNT" \
        --private-key "$STARKNET_PRIVATE_KEY" \
        --type oz \
        --silent 2>/dev/null || true
    SNCAST_GLOBAL="--account local --accounts-file deployment/accounts.json"
elif [ "$TARGET" == "public" ]; then
    if [ -f "deployment/public.env" ]; then
        source deployment/public.env
    else
        echo "Error: deployment/public.env not found."
        exit 1
    fi
    SNCAST_GLOBAL="--account $STARKNET_ACCOUNT --keystore $STARKNET_KEYSTORE"
    if [ -n "$STARKNET_PASSWORD_FILE" ]; then
        SNCAST_GLOBAL="$SNCAST_GLOBAL --password-file $STARKNET_PASSWORD_FILE"
    fi
else
    echo "Error: Unknown deployment target '$TARGET'. Use 'local' or 'public'."
    exit 1
fi

echo "--- Building Epicue Framework ---"
scarb build

# Function to check local node
check_local_node() {
    if [ "$TARGET" == "local" ]; then
        if ! curl -s $STARKNET_RPC > /dev/null; then
            echo "Error: Local node (Devnet) not detected at $STARKNET_RPC."
            echo "Please start the node first in a separate terminal using:"
            echo "  ./run_devnet.sh"
            exit 1
        fi
    fi
}

check_local_node

echo "--- Declaring Registry Contract ---"
# Note: sncast global flags (account, accounts-file) go BEFORE subcommand
# Target-specific flags (url, contract-name) go AFTER
echo "Declaring class..."
# We use || true here because declare often fails if already declared
DECLARE_OUT=$(sncast $SNCAST_GLOBAL --profile "$TARGET" declare --url "$STARKNET_RPC" --contract-name Registry 2>&1) || true

if echo "$DECLARE_OUT" | grep -q "already declared"; then
    echo "Registry class already declared. Skipping declaration."
else
    echo "$DECLARE_OUT"
fi

# Extraction strategy: Robustly pick the first 0x hex string (class hash)
CLASS_HASH=$(echo "$DECLARE_OUT" | grep -ioE "0x[0-9a-f]{64}" | head -n 1)

if [ -z "$CLASS_HASH" ]; then
    echo "Error: Could not determine class hash for Registry."
    echo "Full output for debugging:"
    echo "$DECLARE_OUT"
    exit 1
fi

echo "Successfully identified Registry class hash: $CLASS_HASH"

echo "--- Deploying Registry Instance ---"
# Constructor takes initial_authority (ContractAddress)
DEPLOY_OUT=$(sncast $SNCAST_GLOBAL --profile "$TARGET" deploy --url "$STARKNET_RPC" --class-hash "$CLASS_HASH" --arguments "$STARKNET_ACCOUNT" 2>&1)
echo "$DEPLOY_OUT"

CONTRACT_ADDRESS=$(echo "$DEPLOY_OUT" | grep -ioE "0x[0-9a-f]{64}" | head -n 1)

echo "--------------------------------------------------"
echo "Epicue Registry Deployed Successfully!"
echo "Target: $TARGET"
echo "Address: $CONTRACT_ADDRESS"
echo "Initial Authority: $STARKNET_ACCOUNT"
echo "--------------------------------------------------"

# Configure Portal
echo "VITE_REGISTRY_ADDRESS=$CONTRACT_ADDRESS" > portal/.env.local
echo "Updated portal/.env.local with the new Registry address."
