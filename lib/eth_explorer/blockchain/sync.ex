defmodule EthExplorer.Blockchain.Sync do
  @moduledoc """
  Handles synchronization of blockchain data from an Ethereum node to the database
  """

  alias EthExplorer.Repo
  alias EthExplorer.Ethereum.Client
  alias EthExplorer.Blockchain.{Block, Transaction, Log}

  @doc """
  Fetches and stores a block by number, including its transactions and logs.
  Skips empty blocks (blocks with no transactions).
  """
  def sync_block(block_number, rpc_url \\ "http://localhost:8545") do
    with {:ok, eth_block} <- Client.get_block_by_number(block_number, true, rpc_url) do
      # Skip empty blocks
      if length(eth_block["transactions"]) == 0 do
        {:ok, :skipped_empty_block}
      else
        # Extract block data
        block_attrs = Block.from_eth_block(eth_block)
        
        # Insert block
        {:ok, block} = create_block(block_attrs)
        
        # Process transactions
        process_transactions(eth_block["transactions"], block, rpc_url)
        
        {:ok, block}
      end
    end
  end

  @doc """
  Fetches the latest block number and syncs all blocks from the last known block
  """
  def sync_blockchain(rpc_url \\ "http://localhost:8545") do
    with {:ok, latest_block_number} <- Client.get_block_number(rpc_url) do
      # Get the last synced block number from the database
      last_synced_block = get_last_synced_block()
      
      # Start syncing from the next block after the last synced one
      start_block = if last_synced_block, do: last_synced_block.number + 1, else: 0
      
      # Only sync if there are new blocks
      if start_block <= latest_block_number do
        sync_block_range(start_block, latest_block_number, rpc_url)
      else
        {:ok, :already_synced}
      end
    end
  end

  @doc """
  Syncs a range of blocks
  """
  def sync_block_range(start_block, end_block, rpc_url \\ "http://localhost:8545") do
    Enum.each(start_block..end_block, fn block_number ->
      case sync_block(block_number, rpc_url) do
        {:ok, block} when is_struct(block) -> 
          IO.puts("Synced block #{block.number}")
        {:ok, :skipped_empty_block} -> 
          IO.puts("Skipped empty block #{block_number}")
        {:error, error} -> 
          IO.puts("Error syncing block #{block_number}: #{inspect(error)}")
      end
    end)
    
    {:ok, :sync_completed}
  end

  # Creates a block record
  defp create_block(attrs) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :number)
  end

  # Process transactions from a block and their receipts
  defp process_transactions(transactions, block, rpc_url) do
    Enum.each(transactions, fn eth_tx ->
      # Get transaction receipt for logs and status
      {:ok, receipt} = Client.get_transaction_receipt(eth_tx["hash"], rpc_url)
      
      # Build transaction attributes
      tx_attrs = Transaction.from_eth_transaction(eth_tx, receipt)
                |> Map.put(:block_id, block.id)
      
      # Insert transaction
      {:ok, transaction} = create_transaction(tx_attrs)
      
      # Process logs
      process_logs(receipt["logs"], block, transaction, rpc_url)
    end)
  end

  # Creates a transaction record
  defp create_transaction(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :hash)
  end

  # Process logs from a transaction receipt
  defp process_logs(logs, block, transaction, _rpc_url) do
    Enum.each(logs, fn eth_log ->
      # Build log attributes
      log_attrs = Log.from_eth_log(eth_log)
                 |> Map.put(:block_id, block.id)
                 |> Map.put(:transaction_id, transaction.id)
      
      # Insert log
      create_log(log_attrs)
    end)
  end

  # Creates a log record
  defp create_log(attrs) do
    %Log{}
    |> Log.changeset(attrs)
    |> Repo.insert()
  end

  # Get the last synced block from the database
  defp get_last_synced_block do
    import Ecto.Query
    
    Repo.one(
      from b in Block,
      order_by: [desc: b.number],
      limit: 1
    )
  end
end