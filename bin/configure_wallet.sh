#!/bin/bash

# Epicue Wallet Integration & Local Configuration Helper
# Displays copy-pasteable configuration to integrate browser wallets (ArgentX / Braavos)
# with the local Epicue Devnet.

# Load devnet credentials
if [ -f "deployment/local.env" ]; then
    source deployment/local.env
else
    STARKNET_ACCOUNT="0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691"
    STARKNET_PRIVATE_KEY="0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9"
fi

cat << EOF
======================================================================
                 EPICUE WALLET CONFIGURATION HELPER
======================================================================

Browser wallets (Argent X & Braavos) run in browser sandboxes, meaning they
cannot be configured automatically via shell scripts. Use the following
parameters to connect your wallet to the local Epicue Devnet:

----------------------------------------------------------------------
1. ADD CUSTOM NETWORK TO WALLET (Argent X / Braavos)
----------------------------------------------------------------------
- Open your browser wallet (Argent X or Braavos).
- Click the network selector dropdown (top menu).
- Select "Add Custom Network" or "Settings" -> "Developer Settings" -> "Networks".
- Enter the following details:
  * Network Name: Epicue Local Devnet
  * RPC URL:      http://localhost:5050
  * Chain ID:     devnet (or hex: 0x6465766e6574)

----------------------------------------------------------------------
2. IMPORT PRE-FUNDED DEVNET ACCOUNT
----------------------------------------------------------------------
Epicue Devnet initializes deterministic pre-funded accounts. Import this key
to execute admin/authority node actions locally:

  * Account Type: OpenZeppelin (OZ)
  * Address:      $STARKNET_ACCOUNT
  * Private Key:  $STARKNET_PRIVATE_KEY

----------------------------------------------------------------------
3. END-TO-END VALIDATION STEPS
----------------------------------------------------------------------
- Select the "Epicue Local Devnet" network in your browser wallet extension.
- Import the private key above.
- Open the Epicue Portal at http://localhost:3001
- Click "Connect Wallet", select your wallet, and approve the connection.
- You can now sign governance actions, onboard members, and vote natively!
======================================================================
EOF
