defmodule TestServer do
  def run do
    IO.puts("Testing server configuration...")
    
    # Read the Phoenix endpoint configuration
    Application.ensure_all_started(:eth_explorer)
    config = Application.get_env(:eth_explorer, EthExplorerWeb.Endpoint)
    
    # Extract the HTTP configuration
    http_config = Keyword.get(config, :http, [])
    ip = Keyword.get(http_config, :ip, {127, 0, 0, 1})
    port = Keyword.get(http_config, :port, 4000)
    
    # Convert IP to string
    ip_string = ip |> Tuple.to_list() |> Enum.join(".")
    
    IO.puts("Phoenix is configured to listen on #{ip_string}:#{port}")
    
    # Try to open a socket on that port to see if it's available
    case :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        IO.puts("Port #{port} is available - no server is running on it")
        :gen_tcp.close(socket)
      {:error, reason} ->
        IO.puts("Port #{port} is NOT available - Error: #{inspect(reason)}")
    end
    
    # Try to open a socket on port 3000 as well
    case :gen_tcp.listen(3000, [:binary, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        IO.puts("Port 3000 is available - no server is running on it")
        :gen_tcp.close(socket)
      {:error, reason} ->
        IO.puts("Port 3000 is NOT available - Error: #{inspect(reason)}")
    end
    
    # Try to make an HTTP request to the Phoenix server
    IO.puts("\nTrying to make an HTTP request to http://localhost:#{port}...")
    case :httpc.request(:get, {'http://localhost:#{port}', []}, [], []) do
      {:ok, {{_, status, _}, _, _}} ->
        IO.puts("Request succeeded with status code #{status}")
      {:error, reason} ->
        IO.puts("Request failed: #{inspect(reason)}")
    end
    
    IO.puts("\nTrying to make an HTTP request to http://localhost:3000...")
    case :httpc.request(:get, {'http://localhost:3000', []}, [], []) do
      {:ok, {{_, status, _}, _, _}} ->
        IO.puts("Request succeeded with status code #{status}")
      {:error, reason} ->
        IO.puts("Request failed: #{inspect(reason)}")
    end
  end
end

TestServer.run()