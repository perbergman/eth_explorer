defmodule EthExplorer.Blockchain.Log do
  use Ecto.Schema
  import Ecto.Changeset
  alias EthExplorer.Blockchain.{Block, Transaction}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "logs" do
    field :address, :string
    field :data, :string
    field :topic0, :string
    field :topic1, :string
    field :topic2, :string
    field :topic3, :string
    field :log_index, :integer
    field :block_number, :integer
    field :block_hash, :string
    field :transaction_hash, :string
    field :transaction_index, :integer
    
    # Associations
    belongs_to :block, Block
    belongs_to :transaction, Transaction

    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [
      :address, :data, :topic0, :topic1, :topic2, :topic3, :log_index,
      :block_number, :block_hash, :transaction_hash, :transaction_index,
      :block_id, :transaction_id
    ])
    |> validate_required([:address, :block_number, :block_hash, :transaction_hash])
  end

  @doc """
  Creates a log record from Ethereum JSON-RPC response.
  """
  def from_eth_log(eth_log) do
    # Extract topics
    topics = eth_log["topics"] || []
    topic0 = Enum.at(topics, 0)
    topic1 = Enum.at(topics, 1)
    topic2 = Enum.at(topics, 2)
    topic3 = Enum.at(topics, 3)

    %{
      address: eth_log["address"],
      data: eth_log["data"],
      topic0: topic0,
      topic1: topic1,
      topic2: topic2,
      topic3: topic3,
      log_index: hex_to_integer(eth_log["logIndex"]),
      block_number: hex_to_integer(eth_log["blockNumber"]),
      block_hash: eth_log["blockHash"],
      transaction_hash: eth_log["transactionHash"],
      transaction_index: hex_to_integer(eth_log["transactionIndex"])
    }
  end

  # Helper functions to convert Ethereum hex values
  defp hex_to_integer(nil), do: nil
  defp hex_to_integer("0x" <> hex_str) do
    {num, _} = Integer.parse(hex_str, 16)
    num
  end
  defp hex_to_integer(hex_str) when is_binary(hex_str) do
    {num, _} = Integer.parse(hex_str, 16)
    num
  end
  defp hex_to_integer(num) when is_integer(num), do: num
end