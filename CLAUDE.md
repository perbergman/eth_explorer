# Claude Development Notes

## Quick Commands

### Development Server
```bash
# Start Phoenix server
mix phx.server

# Start Phoenix server in background
nohup mix phx.server > server.log 2>&1 &

# Kill server processes
pkill -f "mix phx.server"
```

### Database
```bash
# Reset database (drop, create, migrate)
mix ecto.reset

# Run migrations only
mix ecto.migrate

# Create database
mix ecto.create
```

### Docker Services
```bash
# Start PostgreSQL
docker-compose up -d

# Start Besu node
./start-besu.sh

# Check running containers
docker ps
```

### Blockchain Interaction
```bash
# Check latest block number
curl -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Get transaction by hash
curl -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["TRANSACTION_HASH"],"id":1}'

# Check gas price
curl -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}'
```

## Project Structure

### Key Components
- **Blockchain Sync**: `lib/eth_explorer/blockchain/sync.ex` - Syncs blocks from Besu
- **Transaction Signing**: `lib/eth_explorer/ethereum/transaction.ex` - Signs transactions for Besu
- **Ethereum Client**: `lib/eth_explorer/ethereum/client.ex` - JSON-RPC communication
- **Mint Interface**: `lib/eth_explorer_web/live/mint_live/` - Send ETH transactions

### Configuration
- **Chain ID**: 1337 (Besu dev network)
- **Database**: PostgreSQL on port 5432
- **Besu Node**: localhost:8545
- **Phoenix Server**: localhost:4000

## Test Accounts (Pre-funded in Besu)

### Account 1
- Address: `0xfe3b557e8fb62b89f4916b721be55ceb828dbd73`
- Private Key: `8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63`

### Account 2  
- Address: `0x627306090abab3a6e1400e9345bc60c78a8bef57`
- Private Key: `c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3`

### Account 3
- Address: `0xf17f52151ebef6c7334fad080c5704d77216b732`
- Private Key: `ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f`

## Recent Fixes

### Transaction Signing for Besu
- Fixed EIP-155 v calculation: `recovery_id + 35 + (chain_id * 2)`
- Updated chain ID to 1337 for Besu dev network
- Fixed ExSecp256k1 function signatures for compact signatures
- Added dynamic gas price fetching
- Improved error handling for transaction failures

### Application URLs
- Home: http://localhost:4000
- Blocks: http://localhost:4000/blocks
- Mint (Send ETH): http://localhost:4000/mint
- Transaction: http://localhost:4000/tx/TRANSACTION_HASH

## Future Development

### ERC20 Token Support
- Add `tokens` and `token_transfers` tables
- Implement ERC20 ABI for contract interaction
- Parse Transfer events from transaction logs
- Add token balance queries and UI

### Performance Improvements
- Skip empty blocks during sync (saves database space)
- Optimize blockchain sync performance
- Add caching for frequently accessed data
- Implement pagination for large data sets

## Troubleshooting

### Server Won't Start
- Check if port 4000 is in use: `lsof -i :4000`
- Restart PostgreSQL: `docker restart eth_explorer-postgres-1`
- Clear any stuck processes: `pkill -f "mix phx.server"`

### Transaction Not Found
- Check if blockchain sync is running (look for "Synced block" in logs)
- Verify transaction exists in Besu node with curl command above
- Wait for sync to catch up to the block containing your transaction

### Database Issues
- Reset database: `mix ecto.reset`
- Check PostgreSQL container: `docker ps | grep postgres`
- Restart PostgreSQL if needed: `docker restart eth_explorer-postgres-1`