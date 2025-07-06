defmodule EthExplorerWeb.TransactionLive.Show do
  use EthExplorerWeb, :live_view

  alias EthExplorer.Repo
  alias EthExplorer.Blockchain.Transaction

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case get_transaction(id) do
      {:ok, transaction} ->
        {:ok, assign(socket, transaction: transaction, error: nil)}
      {:error, reason} ->
        {:ok, assign(socket, transaction: nil, error: reason)}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Transaction Details")
     |> assign(:transaction_id, id)}
  end

  defp get_transaction(hash) do
    import Ecto.Query

    case Repo.one(
      from tx in Transaction,
      where: tx.hash == ^hash,
      preload: [:block, :logs]
    ) do
      nil -> 
        # Try to fetch from the blockchain if not in database
        with {:ok, eth_tx} <- EthExplorer.Ethereum.Client.get_transaction_by_hash(hash),
             {:ok, receipt} <- EthExplorer.Ethereum.Client.get_transaction_receipt(hash) do
          
          # If we found it from RPC, let's save it to the database
          tx_data = Transaction.from_eth_transaction(eth_tx, receipt)
          
          # We'll just return it without saving to DB for now, since we'd need the block
          {:ok, struct(Transaction, tx_data)}
        else
          _ -> {:error, "Transaction not found in database or blockchain"}
        end
      transaction -> 
        {:ok, transaction}
    end
  end


  defp wei_to_eth(wei) when is_nil(wei), do: "0"
  defp wei_to_eth(wei) do
    wei
    |> Decimal.div(Decimal.new(1_000_000_000_000_000_000))
    |> Decimal.to_string(:normal)
  end
end