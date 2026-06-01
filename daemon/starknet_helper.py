#!/usr/bin/env python3
import sys
import subprocess
import os
import re

# Load contract address from portal/.env.local
def get_contract_address():
    try:
        with open("portal/.env.local", "r") as f:
            for line in f:
                if line.startswith("VITE_REGISTRY_ADDRESS="):
                    return line.strip().split("=")[1]
    except Exception:
        pass
    # Fallback to default
    return "0x07d8c48f6ed62a27846d0880f9be373862ac822a44c42760591a6960abc00347"

def get_starknet_config():
    # Defaults (local devnet)
    rpc = "http://localhost:5050"
    account = "local"
    accounts_file = "deployment/accounts.json"
    keystore = ""
    password = ""
    
    # Try reading deployment/.env
    if os.path.exists("deployment/.env"):
        try:
            with open("deployment/.env", "r") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" in line:
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip().strip('"').strip("'")
                        if k == "STARKNET_RPC":
                            rpc = v
                        elif k == "STARKNET_ACCOUNT":
                            account = v
                        elif k == "STARKNET_KEYSTORE":
                            keystore = v
                        elif k == "STARKNET_PASSWORD_FILE":
                            password = v
        except Exception:
            pass
            
    return {
        "rpc": rpc,
        "account": account,
        "accounts_file": accounts_file,
        "keystore": keystore,
        "password": password
    }

def build_sncast_cmd(is_invoke, function_name, calldata_args):
    config = get_starknet_config()
    addr = get_contract_address()
    
    cmd = ["sncast"]
    
    # Check if using local devnet or public/Sepolia
    if "localhost" in config["rpc"] or "127.0.0.1" in config["rpc"]:
        cmd += [
            "--accounts-file", config["accounts_file"],
            "--account", "local"
        ]
    else:
        cmd += [
            "--account", config["account"]
        ]
        if config["keystore"]:
            cmd += ["--keystore", config["keystore"]]
        if config["password"]:
            cmd += ["--keystore-password-file", config["password"]]

    cmd += [
        "invoke" if is_invoke else "call",
        "--url", config["rpc"],
        "--contract-address", addr,
        "--function", function_name
    ]
    
    if is_invoke:
        cmd += ["--calldata"] + calldata_args
    else:
        if calldata_args:
            cmd += ["--arguments"] + calldata_args
            
    return cmd

def poll():
    cmd = build_sncast_cmd(is_invoke=False, function_name="get_record_count", calldata_args=[])
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("ERROR:", result.stderr)
        sys.exit(1)
    
    # Parse record count
    output = result.stdout
    match = re.search(r"Response:\s*(\d+)", output)
    if match:
        count = int(match.group(1))
        print(f"RECORD_COUNT:{count}")
    else:
        print("RECORD_COUNT:0")

def claim(byzantine_node, deviation, total_reviews, proof_hash):
    cmd = build_sncast_cmd(
        is_invoke=True, 
        function_name="claim_security_bounty", 
        calldata_args=[byzantine_node, deviation, total_reviews, proof_hash]
    )
    print(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print("ERROR:", result.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: starknet_helper.py [poll|claim] ...")
        sys.exit(1)
    
    cmd_type = sys.argv[1]
    if cmd_type == "poll":
        poll()
    elif cmd_type == "claim":
        if len(sys.argv) < 6:
            print("Usage: starknet_helper.py claim <node> <deviation> <reviews> <proof_hash>")
            sys.exit(1)
        claim(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    else:
        print("Unknown command:", cmd_type)

if __name__ == "__main__":
    main()
