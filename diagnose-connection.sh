#!/bin/bash

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}============ ETH EXPLORER DIAGNOSTIC TOOL ============${NC}"

echo -e "\n${YELLOW}1. Testing connection to localhost:4000...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:4000 | grep -q "200"; then
  echo -e "${GREEN}✓ Connection successful! Server is responding${NC}"
else
  echo -e "${RED}✗ Connection failed${NC}"
  echo -e "Detailed connection info:"
  curl -v http://localhost:4000 2>&1
fi

echo -e "\n${YELLOW}2. Checking processes using port 4000...${NC}"
if lsof -i :4000 2>/dev/null; then
  echo -e "${GREEN}✓ Process found using port 4000${NC}"
else
  echo -e "${RED}✗ No process found using port 4000${NC}"
fi

echo -e "\n${YELLOW}3. Checking if Phoenix server is running...${NC}"
if ps aux | grep "mix phx" | grep -v grep > /dev/null; then
  echo -e "${GREEN}✓ Phoenix server process found${NC}"
  ps aux | grep "mix phx" | grep -v grep
else
  echo -e "${RED}✗ No Phoenix server process found${NC}"
fi

echo -e "\n${YELLOW}4. Checking Elixir/Erlang processes...${NC}"
if ps aux | grep beam | grep -v grep > /dev/null; then
  echo -e "${GREEN}✓ Elixir/Erlang processes found${NC}"
  ps aux | grep beam | grep -v grep | head -3
  BEAM_COUNT=$(ps aux | grep beam | grep -v grep | wc -l)
  if [ $BEAM_COUNT -gt 3 ]; then
    echo -e "...and $(($BEAM_COUNT - 3)) more"
  fi
else
  echo -e "${RED}✗ No Elixir/Erlang processes found${NC}"
fi

echo -e "\n${YELLOW}5. Checking application logs (last 5 lines)...${NC}"
if [ -f eth_explorer.log ]; then
  echo -e "${GREEN}✓ Log file exists${NC}"
  tail -5 eth_explorer.log
else
  echo -e "${RED}✗ No log file found${NC}"
fi

echo -e "\n${YELLOW}6. Checking database container status...${NC}"
if docker ps | grep -q postgres; then
  echo -e "${GREEN}✓ PostgreSQL container is running${NC}"
  docker ps | grep postgres
else
  echo -e "${RED}✗ PostgreSQL container is not running${NC}"
fi

echo -e "\n${YELLOW}7. Checking blockchain node status...${NC}"
if docker ps | grep -q besu; then
  echo -e "${GREEN}✓ Besu blockchain node is running${NC}"
  docker ps | grep besu
else
  echo -e "${RED}✗ Besu blockchain node is not running${NC}"
fi

echo -e "\n${YELLOW}============ RECOMMENDATION ============${NC}"
echo -e "If you're experiencing issues:"
echo -e "1. Try running ${GREEN}./start-full-explorer.sh${NC} to restart all components"
echo -e "2. Use ${GREEN}./start-phoenix-interactive.sh${NC} for interactive debugging"
echo -e "3. Check the full log with ${GREEN}cat eth_explorer.log${NC} for detailed error messages"