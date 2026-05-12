#!/bin/bash

# Epicue Starknet Sepolia Deployment Script
# Professional automation for EQUISYS framework deployment.

set -e

# Load environment variables
if [ -f "deployment/.env" ]; then
    export $(grep -v '^#' deployment/.env | xargs)
else
    echo "Error: deployment/.env not found."
    echo "Please copy deployment/sepolia.env.template to deployment/.env and populate it."
    exit 1
fi

echo "--- Building Epicue Framework ---"
scarb build

echo "--- Declaring Registry Contract ---"
# Note: --watch is used to wait for inclusion
STARKLI_DECLARE_OUT=$(starkli declare target/dev/epicue_core_Registry.contract_class.json --watch)
CLASS_HASH=$(echo "$STARKLI_DECLARE_OUT" | grep "Class hash declared:" | awk '{print $4}')

if [ -z "$CLASS_HASH" ]; then
    # Check if already declared
    CLASS_HASH=$(starkli class-hash target/dev/epicue_core_Registry.contract_class.json)
    echo "Contract already declared with hash: $CLASS_HASH"
else
    echo "Successfully declared Registry with hash: $CLASS_HASH"
fi

echo "--- Deploying Registry to Sepolia ---"
# Deploy with the current account as the initial authority
STARKLI_DEPLOY_OUT=$(starkli deploy "$CLASS_HASH" "$STARKNET_ACCOUNT" --watch)
CONTRACT_ADDRESS=$(echo "$STARKLI_DEPLOY_OUT" | grep "Contract deployed at:" | awk '{print $4}')

echo "--------------------------------------------------"
echo "Epicue Registry Deployed Successfully!"
echo "Address: $CONTRACT_ADDRESS"
echo "Network: Starknet Sepolia"
echo "Initial Authority: $STARKNET_ACCOUNT"
echo "--------------------------------------------------"
