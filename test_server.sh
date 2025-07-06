#!/bin/bash

# Kill any existing Phoenix server
pkill -f "mix phx.server" 2>/dev/null || true

# Start Phoenix server in the background
cd /Users/perjbergman/Documents/dev/eth_explorer
PORT=4000 mix phx.server &
SERVER_PID=$!

# Wait a bit for the server to start
echo "Waiting for server to start..."
sleep 5

# Try to connect to the server
echo "Attempting to connect to http://localhost:4000"
curl -I http://localhost:4000

# Kill the server
kill $SERVER_PID 2>/dev/null || true