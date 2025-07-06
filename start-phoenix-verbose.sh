#!/bin/bash

# Navigate to the project directory
cd /Users/perjbergman/Documents/dev/eth_explorer

# Enable more verbose logging
export ELIXIR_ERL_OPTIONS="+W w"
export BANDIT_DEBUG=1
export ERL_AFLAGS="-kernel shell_history enabled"

# Start Phoenix server with debug logging and console mode
mix phx.server