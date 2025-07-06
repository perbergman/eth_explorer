#!/bin/bash

# Navigate to the project directory
cd /Users/perjbergman/Documents/dev/eth_explorer

# Kill any existing Phoenix server
pkill -f "beam.smp" || true

# Clear and reset terminal
clear

# Start Phoenix server in foreground with interactive Elixir shell
echo "Starting Phoenix server with interactive Elixir shell..."
exec iex -S mix phx.server