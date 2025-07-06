#!/bin/bash

# Stop and remove existing container if it exists
docker stop besu-zkp-node 2>/dev/null
docker rm besu-zkp-node 2>/dev/null

# Start Besu node with high gas limit
docker run -d --name besu-zkp-node \
  -p 8545:8545 -p 8546:8546 \
  hyperledger/besu:latest \
  --network=dev \
  --miner-enabled \
  --miner-coinbase=0xfe3b557e8fb62b89f4916b721be55ceb828dbd73 \
  --rpc-http-cors-origins="all" \
  --host-allowlist="*" \
  --rpc-http-enabled \
  --rpc-http-api=ETH,NET,WEB3,DEBUG,ADMIN,TXPOOL \
  --rpc-ws-enabled \
  --rpc-ws-api=ETH,NET,WEB3,DEBUG,ADMIN,TXPOOL \
  --revert-reason-enabled=true

# Make the script executable
chmod +x start-besu.sh

echo "Besu node started. Waiting for it to initialize..."
sleep 5
docker logs besu-zkp-node | tail -n 10
echo "Besu node is running. You can now deploy contracts with: npx hardhat run deploy.js --network besuLocal"
