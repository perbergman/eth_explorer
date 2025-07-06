defmodule EthExplorer.Blockchain.Block do
  use Ecto.Schema
  import Ecto.Changeset
  alias EthExplorer.Blockchain.Transaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "blocks" do
    field :number, :integer
    field :hash, :string
    field :parent_hash, :string
    field :nonce, :string
    field :sha3_uncles, :string
    field :logs_bloom, :string
    field :transactions_root, :string
    field :state_root, :string
    field :receipts_root, :string
    field :miner, :string
    field :difficulty, :decimal
    field :total_difficulty, :decimal
    field :size, :integer
    field :extra_data, :string
    field :gas_limit, :integer
    field :gas_used, :integer
    field :timestamp, :integer
    field :transaction_count, :integer

    # Associations
    has_many :transactions, Transaction

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [
      :number, :hash, :parent_hash, :nonce, :sha3_uncles, :logs_bloom,
      :transactions_root, :state_root, :receipts_root, :miner, :difficulty,
      :total_difficulty, :size, :extra_data, :gas_limit, :gas_used,
      :timestamp, :transaction_count
    ])
    |> validate_required([:number, :hash, :parent_hash])
    |> unique_constraint(:number)
    |> unique_constraint(:hash)
  end

  @doc """
  Creates a block record from Ethereum JSON-RPC response.
  """
  def from_eth_block(eth_block) do
    %{
      number: hex_to_integer(eth_block["number"]),
      hash: eth_block["hash"],
      parent_hash: eth_block["parentHash"],
      nonce: eth_block["nonce"],
      sha3_uncles: eth_block["sha3Uncles"],
      logs_bloom: eth_block["logsBloom"],
      transactions_root: eth_block["transactionsRoot"],
      state_root: eth_block["stateRoot"],
      receipts_root: eth_block["receiptsRoot"],
      miner: eth_block["miner"],
      difficulty: hex_to_integer(eth_block["difficulty"]),
      total_difficulty: hex_to_integer(eth_block["totalDifficulty"]),
      size: hex_to_integer(eth_block["size"]),
      extra_data: eth_block["extraData"],
      gas_limit: hex_to_integer(eth_block["gasLimit"]),
      gas_used: hex_to_integer(eth_block["gasUsed"]),
      timestamp: hex_to_integer(eth_block["timestamp"]),
      transaction_count: length(eth_block["transactions"])
    }
  end

  # Helper functions to convert Ethereum hex values to integers
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