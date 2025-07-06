# Ethereum Blockchain Explorer

An Ethereum blockchain explorer built with Elixir, Phoenix, and LiveView that allows you to explore blocks, transactions, and addresses from a Besu node.

## Features

- Real-time blockchain data syncing from a Besu Ethereum node
- Browse blocks, transactions, and addresses
- View transaction details including event logs
- Mint/send transactions using private keys
- PostgreSQL database for storing blockchain data

## Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- Phoenix 1.7 or later
- Docker and Docker Compose
- A running Besu Ethereum node (setup included)

## Quick Start

1. Make sure Docker is running
2. Run the start script:

```bash
./start-full-explorer.sh
```

3. Open your browser and navigate to [http://localhost:4000](http://localhost:4000)

## Manual Setup

If you prefer to start components manually:

1. Start PostgreSQL in Docker:

```bash
docker-compose up -d postgres
```

2. Create and migrate the database:

```bash
mix ecto.create
mix ecto.migrate
```

3. Start the Phoenix server:

```bash
mix phx.server
```

## Troubleshooting

If you encounter any issues:

1. Run the diagnostics script:

```bash
./diagnose-connection.sh
```

2. Start the Phoenix server in interactive mode:

```bash
./start-phoenix-interactive.sh
```

3. Check the log file:

```bash
tail -f eth_explorer.log
```

## Architecture

- **Backend**: Elixir/Phoenix application with GenServer for blockchain synchronization
- **Database**: PostgreSQL for storing blocks, transactions, and logs
- **Frontend**: Phoenix LiveView for real-time UI updates
- **Blockchain Node**: Besu Ethereum client

## Error Handling

The explorer includes robust error handling for:
- Non-existent blocks, transactions, and addresses
- Network connectivity issues with the Ethereum node
- Invalid blockchain data format

## Development

For development, use the interactive Phoenix server:

```bash
./start-phoenix-interactive.sh
```

This provides an IEx shell for debugging and exploring the application.

## Learn more

  * Phoenix Framework: https://www.phoenixframework.org/
  * Ethereum: https://ethereum.org/
  * Besu: https://besu.hyperledger.org/
