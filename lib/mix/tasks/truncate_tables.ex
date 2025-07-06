defmodule Mix.Tasks.TruncateTables do
  @moduledoc """
  Truncates all application tables while preserving the schema.
  
  This is useful for resetting data without going through the full drop/create/migrate cycle.
  
  ## Usage
  
      mix truncate_tables
      
  This will:
  - Connect to the configured database
  - Find all application tables
  - Truncate them in the correct order (handling foreign keys)
  - Reset auto-increment sequences
  """
  
  use Mix.Task
  
  alias EthExplorer.Repo
  import Ecto.Adapters.SQL, only: [query!: 3]
  
  @shortdoc "Truncates all application tables"
  
  def run(_args) do
    Mix.Task.run("app.start")
    
    IO.puts("🗑️  Truncating all application tables...")
    
    try do
      truncate_all_tables()
      IO.puts("✅ All tables truncated successfully!")
    rescue
      error ->
        IO.puts("❌ Error truncating tables: #{inspect(error)}")
        System.halt(1)
    end
  end
  
  defp truncate_all_tables do
    # Get all application tables (excluding system tables)
    query_text = """
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE 'schema_%'
    ORDER BY table_name;
    """
    
    %{rows: rows} = query!(Repo, query_text, [])
    table_names = Enum.map(rows, fn [table_name] -> table_name end)
    
    if Enum.empty?(table_names) do
      IO.puts("ℹ️  No application tables found")
    else
      IO.puts("Found tables: #{Enum.join(table_names, ", ")}")
      
      # Truncate tables in dependency order (child tables first)
      # logs -> transactions -> blocks
      ordered_tables = ["logs", "transactions", "blocks"]
      
      # Only truncate tables that actually exist
      tables_to_truncate = Enum.filter(ordered_tables, fn table -> table in table_names end)
      
      # Add any remaining tables not in our ordered list
      remaining_tables = table_names -- tables_to_truncate
      all_tables = tables_to_truncate ++ remaining_tables
      
      IO.puts("Truncating in order: #{Enum.join(all_tables, " -> ")}")
      
      # Truncate each table with restart identity to reset sequences
      Enum.each(all_tables, fn table_name ->
        IO.puts("  🗑️  Truncating #{table_name}...")
        query!(Repo, "TRUNCATE TABLE #{table_name} RESTART IDENTITY CASCADE;", [])
      end)
    end
  end
end