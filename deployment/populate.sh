#!/bin/bash

# Epicue Test Data Populator
# Submits multiple verifiable records to the Registry for simulation.

set -e

# Load Environment
if [ -f "deployment/local.env" ]; then
    source deployment/local.env
else
    echo "Error: deployment/local.env not found."
    exit 1
fi

# Get Registry Address from portal config
if [ -f "portal/.env.local" ]; then
    CONTRACT_ADDRESS=$(grep VITE_REGISTRY_ADDRESS portal/.env.local | cut -d'=' -f2)
else
    echo "Error: portal/.env.local not found. Run ./deployment/deploy.sh first."
    exit 1
fi

echo "--- Populating Epicue Registry ---"
echo "Target: $CONTRACT_ADDRESS"
echo "------------------------------------------------"

SNCAST_CMD="sncast --accounts-file deployment/accounts.json --account local invoke --url $STARKNET_RPC --contract-address $CONTRACT_ADDRESS"

function submit_record() {
    local subject_id=$1
    local data_hash=$2
    echo "Submitting record $subject_id..."
    $SNCAST_CMD --function submit_record --calldata "$subject_id" "$data_hash" > /dev/null
}

# Submit 3 test records
submit_record "0xabc123" "0xfeedbeef"
submit_record "0xdef456" "0xdeadc0de"
submit_record "0x789abc" "0xbaaaaaad"

echo "------------------------------------------------"
echo "Population Complete!"
echo "Check your portal at http://localhost:3001"
echo "------------------------------------------------"
