defmodule SimpleServer do
  def run do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:eth_explorer)
    
    IO.puts("Checking if we can start a server on port 3000...")
    case :inets.start(:httpd, [
      port: 3000,
      server_name: 'test_server',
      server_root: '.',
      document_root: '.',
      bind_address: {0, 0, 0, 0}
    ]) do
      {:ok, pid} ->
        IO.puts("Server started successfully on port 3000")
        :inets.stop(:httpd, pid)
      {:error, reason} ->
        IO.puts("Failed to start server on port 3000: #{inspect(reason)}")
    end
  end
end

SimpleServer.run()