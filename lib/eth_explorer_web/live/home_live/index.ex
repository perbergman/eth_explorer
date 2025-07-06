defmodule EthExplorerWeb.HomeLive.Index do
  use EthExplorerWeb, :live_view

  alias EthExplorer.Repo
  alias EthExplorer.Blockchain.{Block, Transaction}
  alias EthExplorer.Ethereum.Client

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Start periodic updates
      Process.send_after(self(), :update_data, 500)
    end
    
    socket =
      socket
      |> assign(:latest_blocks, [])
      |> assign(:latest_transactions, [])
      |> assign(:search_query, "")
      |> assign(:search_error, nil)
      |> assign(:network_status, %{
        latest_block: nil,
        gas_price: nil,
        connected: false
      })
    
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Ethereum Explorer")
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    # Validate the search query
    cond do
      # Check if it's a block number
      Regex.match?(~r/^\d+$/, query) ->
        block_number = String.to_integer(query)
        redirect_to = ~p"/blocks/#{block_number}"
        {:noreply, push_navigate(socket, to: redirect_to)}
      
      # Check if it's a transaction hash
      Regex.match?(~r/^0x[a-fA-F0-9]{64}$/, query) ->
        redirect_to = ~p"/tx/#{query}"
        {:noreply, push_navigate(socket, to: redirect_to)}
      
      # Check if it's an address
      Regex.match?(~r/^0x[a-fA-F0-9]{40}$/, query) ->
        redirect_to = ~p"/address/#{query}"
        {:noreply, push_navigate(socket, to: redirect_to)}
      
      # Invalid query
      true ->
        {:noreply, assign(socket, :search_error, "Invalid search query")}
    end
  end

  @impl true
  def handle_info(:update_data, socket) do
    # Schedule the next update in 15 seconds
    Process.send_after(self(), :update_data, 15_000)
    
    socket =
      socket
      |> assign(:latest_blocks, list_latest_blocks())
      |> assign(:latest_transactions, list_latest_transactions())
      |> assign(:network_status, get_network_status())
    
    {:noreply, socket}
  end

  defp list_latest_blocks do
    import Ecto.Query
    
    Repo.all(
      from b in Block,
      order_by: [desc: b.number],
      limit: 5,
      preload: [:transactions]
    )
  end

  defp list_latest_transactions do
    import Ecto.Query
    
    Repo.all(
      from tx in Transaction,
      order_by: [desc: tx.block_number, desc: tx.transaction_index],
      limit: 5,
      preload: [:block]
    )
  end

  defp get_network_status do
    latest_block_result = Client.get_block_number()
    gas_price_result = Client.get_gas_price()
    
    %{
      latest_block: (with {:ok, block_number} <- latest_block_result, do: block_number),
      gas_price: (with {:ok, gas_price} <- gas_price_result, do: gas_price),
      connected: latest_block_result != {:error, :timeout} && gas_price_result != {:error, :timeout}
    }
  end

  defp format_timestamp(nil), do: "N/A"
  defp format_timestamp(timestamp) do
    timestamp
    |> DateTime.from_unix()
    |> case do
      {:ok, datetime} -> Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
      _ -> "Invalid Timestamp"
    end
  end

  defp format_hash(hash, length \\ 10) do
    "#{String.slice(hash, 0, length)}..."
  end

  defp format_gas_price(nil), do: "N/A"
  defp format_gas_price(gas_price) do
    gwei = gas_price / 1_000_000_000
    "#{Float.round(gwei, 2)} Gwei"
  end
end