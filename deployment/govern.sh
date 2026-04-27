#!/bin/bash

# Epicue Governance Automator
# Automates the Proposal -> Vote -> Execute lifecycle for institutional changes.

set -e

# Load Environment
if [ -f "deployment/local.env" ]; then
    source deployment/local.env
else
    echo "Error: deployment/local.env not found."
    exit 1
fi

# Get Registry Address
if [ -f "portal/.env.local" ]; then
    CONTRACT_ADDRESS=$(grep VITE_REGISTRY_ADDRESS portal/.env.local | cut -d'=' -f2)
else
    echo "Error: portal/.env.local not found."
    exit 1
fi

TARGET_AUTH=$1
if [ -z "$TARGET_AUTH" ]; then
    echo "Usage: ./deployment/govern.sh <NEW_AUTHORITY_ADDRESS>"
    echo "Example: ./deployment/govern.sh 0x1234..."
    exit 1
fi

SNCAST_CMD="sncast --accounts-file deployment/accounts.json --account local --wait invoke --url $STARKNET_RPC --contract-address $CONTRACT_ADDRESS"

echo "--- Initiating Governance Flow ---"
echo "Target Authority: $TARGET_AUTH"
echo "------------------------------------------------"

# 1. Propose ADD_AUTH
# 'ADD_AUTH' in hex is 0x4144445f41555448
echo "1. Creating Proposal (ADD_AUTH)..."
PROP_OUT=$($SNCAST_CMD --function propose_action --calldata "$TARGET_AUTH" "0x4144445f41555448")

# 2. Get the new Proposal ID
PROP_COUNT_JSON=$(sncast --accounts-file deployment/accounts.json --account local --json call --url $STARKNET_RPC --contract-address $CONTRACT_ADDRESS --function get_proposal_count)
PROP_COUNT_HEX=$(echo "$PROP_COUNT_JSON" | grep -oE "0x[0-9a-f]+" | head -1)
PROP_COUNT=$(($PROP_COUNT_HEX))
PROP_ID=$((PROP_COUNT - 1))

echo "Proposal created with ID: $PROP_ID"

# 2. Vote For
echo "2. Casting Consensus Vote..."
$SNCAST_CMD --function vote_on_proposal --calldata "$PROP_ID" "1" > /dev/null

# 3. Execute
echo "3. Executing institutional change..."
$SNCAST_CMD --function execute_proposal --calldata "$PROP_ID" > /dev/null

echo "------------------------------------------------"
echo "Governance Action Complete!"
echo "New Authority Added: $TARGET_AUTH"
echo "Check your BFT Quorum Status in the portal."
echo "------------------------------------------------"
