defmodule EthExplorer.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :integer, null: false
      add :hash, :string, null: false
      add :parent_hash, :string, null: false
      add :nonce, :string
      add :sha3_uncles, :string
      add :logs_bloom, :text
      add :transactions_root, :string
      add :state_root, :string
      add :receipts_root, :string
      add :miner, :string
      add :difficulty, :decimal
      add :total_difficulty, :decimal
      add :size, :integer
      add :extra_data, :text
      add :gas_limit, :bigint
      add :gas_used, :integer
      add :timestamp, :integer
      add :transaction_count, :integer

      timestamps()
    end

    create unique_index(:blocks, [:number])
    create unique_index(:blocks, [:hash])
  end
end
