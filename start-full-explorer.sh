#!/bin/bash

# This script starts the complete Ethereum explorer application
# including Docker container for PostgreSQL and the Phoenix server

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Ethereum Explorer Application${NC}"

# Step 1: Ensure Docker is running
echo -e "\n${YELLOW}Step 1: Checking if Docker is running...${NC}"
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}Docker is not running! Please start Docker Desktop first.${NC}"
  exit 1
fi
echo -e "${GREEN}Docker is running${NC}"

# Step 2: Start PostgreSQL
echo -e "\n${YELLOW}Step 2: Starting PostgreSQL container...${NC}"
docker-compose up -d postgres
echo -e "${GREEN}PostgreSQL container is running${NC}"

# Step 3: Wait for PostgreSQL to be ready
echo -e "\n${YELLOW}Step 3: Waiting for PostgreSQL to be ready...${NC}"
sleep 5
echo -e "${GREEN}PostgreSQL should be ready now${NC}"

# Step 4: Kill any existing Phoenix server processes
echo -e "\n${YELLOW}Step 4: Ensuring no existing Phoenix processes are running...${NC}"
pkill -f "beam.smp" || true
echo -e "${GREEN}No existing Phoenix processes should be running now${NC}"

# Step 5: Run database migrations
echo -e "\n${YELLOW}Step 5: Running database migrations...${NC}"
cd /Users/perjbergman/Documents/dev/eth_explorer
mix ecto.create --quiet || echo "Database already exists"
mix ecto.migrate
echo -e "${GREEN}Database migrations completed${NC}"

# Step 6: Start Phoenix server in background
echo -e "\n${YELLOW}Step 6: Starting Phoenix server...${NC}"
echo -e "${YELLOW}The server will run in the background. You should be able to access it at:${NC}"
echo -e "${GREEN}http://localhost:4000${NC}"
echo -e "\n${YELLOW}If you encounter any issues:${NC}"
echo -e "1. Run ./diagnose-connection.sh to check the status"
echo -e "2. Run ./start-phoenix-interactive.sh for an interactive session\n"

# Start the Phoenix server and suppress output
nohup mix phx.server > eth_explorer.log 2>&1 &

# Wait a few seconds for the server to start
sleep 5

# Check if the server is running by looking for log entries
if grep -q "Running EthExplorerWeb.Endpoint" eth_explorer.log; then
  echo -e "${GREEN}Phoenix server is running in the background${NC}"
  echo -e "${YELLOW}Logs are being written to eth_explorer.log${NC}"
  echo -e "${GREEN}Ethereum Explorer is now starting - please be patient while it syncs blockchain data${NC}"
  echo -e "${GREEN}You can access the explorer at: http://localhost:4000${NC}"
else
  echo -e "${RED}Failed to start Phoenix server${NC}"
  echo -e "${YELLOW}Check eth_explorer.log for errors${NC}"
  exit 1
fi