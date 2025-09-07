#!/bin/bash

# setup.sh: End-to-end setup script for the 0xUSD project.
# This script checks for dependencies, installs them if necessary,
# installs project packages, and runs all tests.

set -e # Exit immediately if a command exits with a non-zero status.

# Helper function for logging
log() {
  echo "--- $1 ---"
}

# --- 1. Dependency Checks ---
log "Checking for required dependencies (git, curl)..."
command -v git >/dev/null 2>&1 || { echo >&2 "Git is not installed. Please install it and re-run."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "cURL is not installed. Please install it and re-run."; exit 1; }
log "Dependencies found."

# --- 2. Install Foundry ---
if ! command -v foundryup &> /dev/null
then
    log "Foundry not found. Installing via foundryup..."
    curl -L https://foundry.paradigm.xyz | bash
    # This will require the user to source their profile or open a new shell.
    # We add it to the current shell's path for this script to continue.
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup
else
    log "Foundry is already installed."
fi
log "Foundry installation complete."

# --- 3. Install pnpm ---
if ! command -v pnpm &> /dev/null
then
    log "pnpm not found. Installing via npm..."
    if ! command -v npm &> /dev/null
    then
        echo >&2 "npm is not installed. Please install Node.js and npm, then re-run."
        exit 1
    fi
    npm install -g pnpm
else
    log "pnpm is already installed."
fi
log "pnpm installation complete."


# --- 4. Install Project Dependencies ---
log "Installing smart contract dependencies..."
forge install
log "Smart contract dependencies installed."

log "Installing SDK dependencies..."
(cd sdk && pnpm install)
log "SDK dependencies installed."


# --- 5. Run Tests ---
log "Running smart contract tests..."
forge test
log "Smart contract tests passed."

log "Running SDK tests..."
(cd sdk && pnpm test)
log "SDK tests passed."


# --- 6. Success & Next Steps ---
log "✅ Setup complete! The 0xUSD project is ready."
echo ""
echo "Next steps:"
echo "1. Start a local node:"
echo "   anvil"
echo ""
echo "2. In a new terminal, deploy the contracts to the local node:"
echo "   source .env.example"
echo "   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast"
echo ""
echo "Happy hacking!"
