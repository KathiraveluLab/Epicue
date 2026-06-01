#!/bin/bash

# Epicue ZK Coprocessor Daemon Runner
# Compiles and starts the Erlang daemon.

set -e

# Check for Erlang erlc and erl
if ! command -v erlc &> /dev/null; then
    echo "Error: erlc (Erlang compiler) not found. Please install Erlang/OTP."
    exit 1
fi

if ! command -v erl &> /dev/null; then
    echo "Error: erl (Erlang runtime) not found. Please install Erlang/OTP."
    exit 1
fi

echo "--- Compiling Epicue Erlang Daemon ---"
erlc -o daemon daemon/auditor.erl

echo "--- Starting ZK Coprocessor Daemon ---"
echo "Press Ctrl+C followed by 'a' to abort."
echo "------------------------------------------------"

erl -noshell -pa daemon -s auditor start
