#!/bin/bash

# Epicue Unified Deployment Script (Epicue Architecture)
# Supports Local (Devnet) and Public (Sepolia) targets.

set -e

# Default target if not specified
TARGET=${EPICUE_DEPLOY_TARGET:-local}

echo "--- Initializing Deployment: Target=$TARGET ---"

# Load environment
if [ "$TARGET" == "local" ]; then
    source deployment/local.env
    echo "Importing local account..."
    sncast --accounts-file deployment/accounts.json account import \
        --url "$STARKNET_RPC" \
        --name local \
        --address "$STARKNET_ACCOUNT" \
        --private-key "$STARKNET_PRIVATE_KEY" \
        --type oz \
        --silent 2>/dev/null || true
    SNCAST_GLOBAL="--account local --accounts-file deployment/accounts.json"
elif [ "$TARGET" == "federated" ]; then
    if [ -f "deployment/federated.env" ]; then
        source deployment/federated.env
    else
        echo "Error: deployment/federated.env not found. Please create it from deployment/federated.env.template."
        exit 1
    fi
    echo "Importing federated account..."
    sncast --accounts-file deployment/accounts.json account import \
        --url "$STARKNET_RPC" \
        --name federated \
        --address "$STARKNET_ACCOUNT" \
        --private-key "$STARKNET_PRIVATE_KEY" \
        --type oz \
        --silent 2>/dev/null || true
    SNCAST_GLOBAL="--account federated --accounts-file deployment/accounts.json"
elif [ "$TARGET" == "madara" ]; then
    if [ -f "deployment/madara.env" ]; then
        source deployment/madara.env
    else
        echo "Error: deployment/madara.env not found. Please create it from deployment/madara.env.template."
        exit 1
    fi
    echo "Importing Madara admin account..."
    sncast --accounts-file deployment/accounts.json account import \
        --url "$STARKNET_RPC" \
        --name madara \
        --address "$STARKNET_ACCOUNT" \
        --private-key "$STARKNET_PRIVATE_KEY" \
        --type oz \
        --silent 2>/dev/null || true
    SNCAST_GLOBAL="--account madara --accounts-file deployment/accounts.json"
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
    echo "Error: Unknown deployment target '$TARGET'. Use 'local', 'federated', 'madara', or 'public'."
    exit 1
fi

echo "--- Building Epicue Framework ---"
scarb build

# Function to check local/remote node connectivity
check_node_connectivity() {
    if ! curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"starknet_blockNumber","params":[],"id":1}' $STARKNET_RPC > /dev/null; then
        echo "Error: Starknet RPC node not detected or unresponsive at $STARKNET_RPC."
        if [ "$TARGET" == "local" ]; then
            echo "Please start the local devnet node first in a separate terminal using:"
            echo "  ./scripts/run_local.sh"
        else
            echo "Please verify that your node is running and the RPC URL is correct in your target env file."
        fi
        exit 1
    fi
}

check_node_connectivity

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

# Extraction strategy: Robustly pick the hex string following "Class Hash:"
CLASS_HASH=$(echo "$DECLARE_OUT" | grep "Class Hash:" | grep -ioE "0x[0-9a-f]+" | head -n 1)

# Fallback: if not found (e.g. already declared), it might be elsewhere in the output
if [ -z "$CLASS_HASH" ]; then
    CLASS_HASH=$(echo "$DECLARE_OUT" | grep -ioE "0x[0-9a-f]+" | head -n 1)
fi

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

CONTRACT_ADDRESS=$(echo "$DEPLOY_OUT" | grep -ioE "0x[0-9a-f]+" | head -n 1)

echo "--------------------------------------------------"
echo "Epicue Registry Deployed Successfully!"
echo "Target: $TARGET"
echo "Address: $CONTRACT_ADDRESS"
echo "Initial Authority: $STARKNET_ACCOUNT"
echo "--------------------------------------------------"

# Configure Portal
echo "VITE_REGISTRY_ADDRESS=$CONTRACT_ADDRESS" > portal/.env.local
echo "Updated portal/.env.local with the new Registry address."
