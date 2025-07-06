defmodule EthExplorerWeb.AddressLive.Show do
  use EthExplorerWeb, :live_view

  alias EthExplorer.Repo
  alias EthExplorer.Blockchain.Transaction
  alias EthExplorer.Ethereum.Client

  @impl true
  def mount(%{"id" => address}, _session, socket) do
    # Validate that it's a valid Ethereum address format
    if valid_ethereum_address?(address) do
      transactions = get_address_transactions(address)
      
      socket =
        socket
        |> assign(:address, address)
        |> assign(:transactions, transactions)
        |> assign(:page, 1)
        |> assign(:per_page, 25)
        |> assign(:balance, nil)
        |> assign(:nonce, nil)
        |> assign(:error, nil)
      
      if connected?(socket) do
        # Get balance and nonce in the background
        send(self(), :load_balance)
      end
      
      {:ok, socket}
    else
      {:ok, 
        socket
        |> assign(:address, nil)
        |> assign(:transactions, [])
        |> assign(:error, "Invalid Ethereum address format")}
    end
  end

  @impl true
  def handle_params(%{"id" => address}, _, socket) do
    title = if socket.assigns[:error], do: "Address Details", else: "Address #{short_address(address)}" 
    
    {:noreply,
     socket
     |> assign(:page_title, title)
     |> assign(:address_id, address)}
  end

  @impl true
  def handle_event("load-more", _, socket) do
    next_page = socket.assigns.page + 1
    new_transactions = get_address_transactions_paginated(socket.assigns.address, next_page, socket.assigns.per_page)
    
    {:noreply, 
     socket
     |> assign(:transactions, socket.assigns.transactions ++ new_transactions)
     |> assign(:page, next_page)}
  end

  @impl true
  def handle_info(:load_balance, socket) do
    # Get balance and nonce from Ethereum node
    balance_result = Client.get_balance(socket.assigns.address)
    nonce_result = Client.get_transaction_count(socket.assigns.address)
    
    socket =
      socket
      |> assign(:balance, (with {:ok, balance} <- balance_result, do: wei_to_eth(balance)))
      |> assign(:nonce, (with {:ok, nonce} <- nonce_result, do: nonce))
    
    # Update the error message if we couldn't connect to the blockchain
    socket = case {balance_result, nonce_result} do
      {{:error, _}, {:error, _}} -> 
        assign(socket, :error, "Unable to connect to Ethereum node to fetch address data")
      _ -> 
        socket
    end
    
    {:noreply, socket}
  end

  defp get_address_transactions(address) do
    get_address_transactions_paginated(address, 1, 25)
  end

  defp get_address_transactions_paginated(address, page, per_page) do
    import Ecto.Query
    
    offset = (page - 1) * per_page
    
    Repo.all(
      from tx in Transaction,
      where: tx.from == ^address or tx.to == ^address,
      order_by: [desc: tx.block_number, desc: tx.transaction_index],
      limit: ^per_page,
      offset: ^offset,
      preload: [:block]
    )
  end

  defp valid_ethereum_address?(address) do
    # Basic validation - check if it's a string starting with 0x followed by 40 hex characters
    case address do
      "0x" <> rest -> String.length(rest) == 40 && Regex.match?(~r/^[0-9a-fA-F]+$/, rest)
      _ -> false
    end
  end

  defp short_address(nil), do: "Invalid Address"
  defp short_address(address) do
    "#{String.slice(address, 0, 6)}...#{String.slice(address, -4, 4)}"
  end

  defp wei_to_eth(wei) when is_nil(wei), do: "0"
  defp wei_to_eth(wei) when is_integer(wei) do
    wei
    |> Decimal.new()
    |> Decimal.div(Decimal.new(1_000_000_000_000_000_000))
    |> Decimal.to_string(:normal)
  end
  defp wei_to_eth(wei), do: wei
end