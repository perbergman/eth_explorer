#!/bin/bash

# Navigate to the project directory
cd /Users/perjbergman/Documents/dev/eth_explorer

# Kill any existing Phoenix server
pkill -f "beam.smp.*eth_explorer"

# Verify if port 4000 is free
netstat -an | grep LISTEN | grep -q ".4000 " && {
  echo "Port 4000 is already in use. Trying to free it..."
  lsof -ti:4000 | xargs kill -9 || true
}

# Start Phoenix server with explicit binding
export MIX_ENV=dev
echo "Starting Phoenix server..."
mix phx.server