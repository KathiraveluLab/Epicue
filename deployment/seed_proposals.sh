#!/bin/bash

# Epicue Governance Seeder
# Seeds the registry with multiple institutional proposals for simulation.

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

SNCAST_CMD="sncast --accounts-file deployment/accounts.json --account local --wait invoke --url $STARKNET_RPC --contract-address $CONTRACT_ADDRESS"

echo "--- Seeding Governance Proposals ---"
echo "------------------------------------------------"

# 1. Add New Institutional Node (Health Authority)
echo "Proposing: Add Health Authority..."
$SNCAST_CMD --function propose_action --calldata "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" "0x4144445f41555448" > /dev/null

# 2. Adjust Reputation Floor (Tighten security)
echo "Proposing: Increase Reputation Floor..."
$SNCAST_CMD --function propose_action --calldata "0x64" "0x5345545f464c4f4f52" > /dev/null

# 3. Add Security Auditor Node
echo "Proposing: Add Security Auditor..."
$SNCAST_CMD --function propose_action --calldata "0x0223456789abcdef0123456789abcdef0123456789abcdef0123456789abcdee" "0x4144445f41555448" > /dev/null

echo "------------------------------------------------"
echo "Governance Seeding Complete!"
echo "Check the Governance tab at http://localhost:3001"
echo "------------------------------------------------"
