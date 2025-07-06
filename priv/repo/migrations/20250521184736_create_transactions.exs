defmodule EthExplorer.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hash, :string, null: false
      add :block_hash, :string, null: false
      add :block_number, :integer, null: false
      add :from, :string, null: false
      add :to, :string
      add :value, :decimal
      add :gas, :decimal
      add :gas_price, :decimal
      add :input, :text
      add :nonce, :integer
      add :transaction_index, :integer
      add :status, :integer
      add :cumulative_gas_used, :decimal
      add :gas_used, :decimal
      add :contract_address, :string

      # Relation to blocks table
      add :block_id, references(:blocks, type: :binary_id)

      timestamps()
    end

    create unique_index(:transactions, [:hash])
    create index(:transactions, [:block_number])
    create index(:transactions, [:from])
    create index(:transactions, [:to])
  end
end
