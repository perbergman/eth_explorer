defmodule EthExplorer.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :address, :string, null: false
      add :data, :text
      add :topic0, :string
      add :topic1, :string
      add :topic2, :string
      add :topic3, :string
      add :log_index, :integer
      add :block_number, :integer, null: false
      add :block_hash, :string, null: false
      add :transaction_hash, :string, null: false
      add :transaction_index, :integer

      # Relations to other tables
      add :block_id, references(:blocks, type: :binary_id)
      add :transaction_id, references(:transactions, type: :binary_id)

      timestamps()
    end

    create index(:logs, [:address])
    create index(:logs, [:topic0])
    create index(:logs, [:topic1])
    create index(:logs, [:topic2])
    create index(:logs, [:topic3])
    create index(:logs, [:block_number])
    create index(:logs, [:transaction_hash])
  end
end
