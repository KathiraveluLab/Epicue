#!/bin/bash

# Epicue Portal Runner
# Starts the institutional portal client.

set -e

# Path to portal directory
PORTAL_DIR="portal"

if [ ! -d "$PORTAL_DIR" ]; then
    echo "Error: Portal directory not found."
    exit 1
fi

cd "$PORTAL_DIR"

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "Warning: .env.local not found. Portal may not be able to find the Registry."
    echo "Please run ./deployment/deploy.sh first to configure it automatically."
fi

# Check for node_modules
if [ ! -d "node_modules" ]; then
    echo "--- Installing Portal Dependencies ---"
    npm install
fi

echo "--- Starting Institutional Portal ---"
echo "URL: http://localhost:3001"
echo "Press Ctrl+C to stop."
echo "------------------------------------------------"

npm run dev
