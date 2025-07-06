defmodule EthExplorer.Ethereum.Client do
  @moduledoc """
  Client for interacting with Ethereum JSON-RPC API
  """

  @doc """
  Makes a JSON-RPC call to the Ethereum node
  """
  def json_rpc_call(method, params, url \\ "http://localhost:8545") do
    request_body = %{
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: 1
    }

    headers = [{"Content-Type", "application/json"}]

    with {:ok, response} <- HTTPoison.post(url, Jason.encode!(request_body), headers),
         {:ok, body} <- Jason.decode(response.body),
         %{"result" => result} <- body do
      {:ok, result}
    else
      %{"error" => error} -> {:error, error}
      error -> {:error, error}
    end
  end

  @doc """
  Gets the latest block number
  """
  def get_block_number(url \\ "http://localhost:8545") do
    case json_rpc_call("eth_blockNumber", [], url) do
      {:ok, block_number_hex} ->
        {block_number, _} = Integer.parse(String.trim_leading(block_number_hex, "0x"), 16)
        {:ok, block_number}
      error -> error
    end
  end

  @doc """
  Gets a block by number
  """
  def get_block_by_number(block_number, include_transactions \\ false, url \\ "http://localhost:8545") do
    block_number_hex = "0x" <> Integer.to_string(block_number, 16)
    json_rpc_call("eth_getBlockByNumber", [block_number_hex, include_transactions], url)
  end

  @doc """
  Gets a block by hash
  """
  def get_block_by_hash(block_hash, include_transactions \\ false, url \\ "http://localhost:8545") do
    json_rpc_call("eth_getBlockByHash", [block_hash, include_transactions], url)
  end

  @doc """
  Gets a transaction by hash
  """
  def get_transaction_by_hash(transaction_hash, url \\ "http://localhost:8545") do
    json_rpc_call("eth_getTransactionByHash", [transaction_hash], url)
  end

  @doc """
  Gets a transaction receipt by hash
  """
  def get_transaction_receipt(transaction_hash, url \\ "http://localhost:8545") do
    json_rpc_call("eth_getTransactionReceipt", [transaction_hash], url)
  end

  @doc """
  Gets logs matching the filter
  """
  def get_logs(filter, url \\ "http://localhost:8545") do
    json_rpc_call("eth_getLogs", [filter], url)
  end

  @doc """
  Sends a raw transaction
  """
  def send_raw_transaction(signed_data, url \\ "http://localhost:8545") do
    json_rpc_call("eth_sendRawTransaction", [signed_data], url)
  end

  @doc """
  Gets the balance of an address
  """
  def get_balance(address, block \\ "latest", url \\ "http://localhost:8545") do
    case json_rpc_call("eth_getBalance", [address, block], url) do
      {:ok, balance_hex} ->
        {balance, _} = Integer.parse(String.trim_leading(balance_hex, "0x"), 16)
        {:ok, balance}
      error -> error
    end
  end

  @doc """
  Gets the transaction count for an address (nonce)
  """
  def get_transaction_count(address, block \\ "latest", url \\ "http://localhost:8545") do
    case json_rpc_call("eth_getTransactionCount", [address, block], url) do
      {:ok, count_hex} ->
        {count, _} = Integer.parse(String.trim_leading(count_hex, "0x"), 16)
        {:ok, count}
      error -> error
    end
  end

  @doc """
  Estimates gas for a transaction
  """
  def estimate_gas(transaction, url \\ "http://localhost:8545") do
    case json_rpc_call("eth_estimateGas", [transaction], url) do
      {:ok, gas_hex} ->
        {gas, _} = Integer.parse(String.trim_leading(gas_hex, "0x"), 16)
        {:ok, gas}
      error -> error
    end
  end

  @doc """
  Gets the current gas price
  """
  def get_gas_price(url \\ "http://localhost:8545") do
    case json_rpc_call("eth_gasPrice", [], url) do
      {:ok, price_hex} ->
        {price, _} = Integer.parse(String.trim_leading(price_hex, "0x"), 16)
        {:ok, price}
      error -> error
    end
  end
end