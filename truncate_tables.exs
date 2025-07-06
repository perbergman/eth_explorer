#!/usr/bin/env elixir

# Truncate all tables script
# This script truncates all application tables while preserving the schema
# Useful for resetting data without dropping/recreating the database

Mix.install([
  {:postgrex, "~> 0.17"},
  {:ecto_sql, "~> 3.10"}
])

defmodule TruncateTables do
  @moduledoc """
  Script to truncate all application tables in the correct order to handle foreign key constraints
  """
  
  def run do
    IO.puts("🗑️  Truncating all application tables...")
    
    # Database connection configuration
    config = [
      hostname: "localhost",
      port: 5432,
      username: "postgres",
      password: "postgres",
      database: "eth_explorer_dev"
    ]
    
    case Postgrex.start_link(config) do
      {:ok, conn} ->
        try do
          truncate_tables(conn)
          IO.puts("✅ All tables truncated successfully!")
        rescue
          error ->
            IO.puts("❌ Error truncating tables: #{inspect(error)}")
        after
          GenServer.stop(conn)
        end
        
      {:error, error} ->
        IO.puts("❌ Failed to connect to database: #{inspect(error)}")
        IO.puts("Make sure PostgreSQL is running and the database exists")
    end
  end
  
  defp truncate_tables(conn) do
    # Get all application tables (excluding system tables)
    query = """
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE 'schema_%'
    ORDER BY table_name;
    """
    
    case Postgrex.query(conn, query, []) do
      {:ok, %{rows: rows}} ->
        table_names = Enum.map(rows, fn [table_name] -> table_name end)
        
        if Enum.empty?(table_names) do
          IO.puts("ℹ️  No application tables found")
        else
          IO.puts("Found tables: #{Enum.join(table_names, ", ")}")
          
          # Disable foreign key checks temporarily
          Postgrex.query!(conn, "SET session_replication_role = replica;", [])
          IO.puts("🔓 Disabled foreign key constraints")
          
          # Truncate each table
          Enum.each(table_names, fn table_name ->
            IO.puts("  🗑️  Truncating #{table_name}...")
            Postgrex.query!(conn, "TRUNCATE TABLE #{table_name} RESTART IDENTITY;", [])
          end)
          
          # Re-enable foreign key checks
          Postgrex.query!(conn, "SET session_replication_role = DEFAULT;", [])
          IO.puts("🔒 Re-enabled foreign key constraints")
        end
        
      {:error, error} ->
        raise "Failed to get table list: #{inspect(error)}"
    end
  end
end

# Run the script
TruncateTables.run()