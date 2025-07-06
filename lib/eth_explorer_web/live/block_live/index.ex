defmodule EthExplorerWeb.BlockLive.Index do
  use EthExplorerWeb, :live_view

  alias EthExplorer.Blockchain
  alias EthExplorer.Repo
  alias EthExplorer.Blockchain.Block

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update_blocks, 500)

    blocks = list_latest_blocks()
    {:ok, assign(socket, blocks: blocks, page: 1, per_page: 10)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Ethereum Blocks")
  end

  @impl true
  def handle_event("load-more", _, socket) do
    next_page = socket.assigns.page + 1
    blocks = list_blocks_paginated(next_page, socket.assigns.per_page)
    
    {:noreply, 
     socket
     |> assign(:blocks, socket.assigns.blocks ++ blocks)
     |> assign(:page, next_page)}
  end

  @impl true
  def handle_info(:update_blocks, socket) do
    # Schedule next update
    Process.send_after(self(), :update_blocks, 15_000)
    
    # Get latest blocks
    blocks = list_latest_blocks()
    
    {:noreply, assign(socket, :blocks, blocks)}
  end

  defp list_latest_blocks do
    import Ecto.Query
    
    Repo.all(
      from b in Block,
      order_by: [desc: b.number],
      limit: 10,
      preload: [:transactions]
    )
  end

  defp list_blocks_paginated(page, per_page) do
    import Ecto.Query
    
    offset = (page - 1) * per_page
    
    Repo.all(
      from b in Block,
      order_by: [desc: b.number],
      limit: ^per_page,
      offset: ^offset,
      preload: [:transactions]
    )
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
end