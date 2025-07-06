defmodule EthExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EthExplorerWeb.Telemetry,
      EthExplorer.Repo,
      {DNSCluster, query: Application.get_env(:eth_explorer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EthExplorer.PubSub},
      # Start the blockchain synchronization service
      {EthExplorer.Blockchain.Service, [rpc_url: "http://localhost:8545", sync_interval: 15_000]},
      # Start to serve requests, typically the last entry
      EthExplorerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EthExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EthExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
