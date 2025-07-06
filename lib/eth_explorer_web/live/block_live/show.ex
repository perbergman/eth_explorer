defmodule EthExplorerWeb.BlockLive.Show do
  use EthExplorerWeb, :live_view

  alias EthExplorer.Repo
  alias EthExplorer.Blockchain.Block

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Integer.parse(id) do
      {block_number, _} ->
        case get_block(block_number) do
          {:ok, block} ->
            {:ok, assign(socket, block: block, error: nil)}
          {:error, reason} ->
            {:ok, assign(socket, block: nil, error: reason)}
        end
      :error ->
        {:ok, assign(socket, block: nil, error: "Invalid block number format")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Block ##{id}")
     |> assign(:block_id, id)}
  end

  defp get_block(number) do
    import Ecto.Query

    case Repo.one(
      from b in Block,
      where: b.number == ^number,
      preload: [transactions: :logs]
    ) do
      nil -> 
        # Try to fetch from the blockchain if not in database
        with {:ok, eth_block} <- EthExplorer.Ethereum.Client.get_block_by_number(number, true) do
          # If we found it from RPC, let's save it to the database
          block_attrs = Block.from_eth_block(eth_block)
          
          # We'll just return it without saving to DB for now
          {:ok, struct(Block, block_attrs)}
        else
          _ -> {:error, "Block not found in database or blockchain"}
        end
      block -> 
        {:ok, block}
    end
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
end