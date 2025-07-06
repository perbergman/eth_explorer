defmodule EthExplorer.Blockchain.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias EthExplorer.Blockchain.{Block, Log}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :hash, :string
    field :block_hash, :string
    field :block_number, :integer
    field :from, :string
    field :to, :string
    field :value, :decimal
    field :gas, :decimal
    field :gas_price, :decimal
    field :input, :string
    field :nonce, :integer
    field :transaction_index, :integer
    field :status, :integer
    field :cumulative_gas_used, :decimal
    field :gas_used, :decimal
    field :contract_address, :string
    
    # Associations
    belongs_to :block, Block
    has_many :logs, Log

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :hash, :block_hash, :block_number, :from, :to, :value, :gas, :gas_price,
      :input, :nonce, :transaction_index, :status, :cumulative_gas_used,
      :gas_used, :contract_address, :block_id
    ])
    |> validate_required([:hash, :block_hash, :block_number, :from])
    |> unique_constraint(:hash)
  end

  @doc """
  Creates a transaction record from Ethereum JSON-RPC response.
  """
  def from_eth_transaction(eth_tx, receipt \\ nil) do
    tx_data = %{
      hash: eth_tx["hash"],
      block_hash: eth_tx["blockHash"],
      block_number: hex_to_integer(eth_tx["blockNumber"]),
      from: eth_tx["from"],
      to: eth_tx["to"],
      value: hex_to_decimal(eth_tx["value"]),
      gas: hex_to_decimal(eth_tx["gas"]),
      gas_price: hex_to_decimal(eth_tx["gasPrice"]),
      input: eth_tx["input"],
      nonce: hex_to_integer(eth_tx["nonce"]),
      transaction_index: hex_to_integer(eth_tx["transactionIndex"])
    }

    # Merge receipt data if available
    if receipt do
      Map.merge(tx_data, %{
        status: hex_to_integer(receipt["status"]),
        cumulative_gas_used: hex_to_decimal(receipt["cumulativeGasUsed"]),
        gas_used: hex_to_decimal(receipt["gasUsed"]),
        contract_address: receipt["contractAddress"]
      })
    else
      tx_data
    end
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

  defp hex_to_decimal(nil), do: nil
  defp hex_to_decimal("0x" <> hex_str) do
    {num, _} = Integer.parse(hex_str, 16)
    Decimal.new(num)
  end
  defp hex_to_decimal(hex_str) when is_binary(hex_str) do
    {num, _} = Integer.parse(hex_str, 16)
    Decimal.new(num)
  end
  defp hex_to_decimal(num) when is_integer(num), do: Decimal.new(num)
end