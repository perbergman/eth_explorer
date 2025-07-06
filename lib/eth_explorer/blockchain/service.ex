defmodule EthExplorer.Blockchain.Service do
  @moduledoc """
  Service to manage blockchain synchronization
  """

  use GenServer
  require Logger

  alias EthExplorer.Blockchain.Sync

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def sync_now do
    GenServer.cast(__MODULE__, :sync_now)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    rpc_url = Keyword.get(opts, :rpc_url, "http://localhost:8545")
    sync_interval = Keyword.get(opts, :sync_interval, 15_000)

    # Schedule initial sync
    Process.send_after(self(), :sync, 5_000)

    {:ok, %{rpc_url: rpc_url, sync_interval: sync_interval, last_synced: nil, syncing: false}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:sync_now, state) do
    if not state.syncing do
      send(self(), :sync)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:sync, state) do
    # Only sync if not already syncing
    if state.syncing do
      Process.send_after(self(), :sync, state.sync_interval)
      {:noreply, state}
    else
      # Mark as syncing
      state = %{state | syncing: true}

      # Perform sync
      Task.start(fn ->
        result = sync_blockchain(state.rpc_url)
        Process.send(self(), {:sync_complete, result}, [])
      end)

      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:sync_complete, result}, state) do
    # Log the result
    case result do
      {:ok, :sync_completed} ->
        Logger.info("Blockchain sync completed successfully")
      
      {:ok, :already_synced} ->
        Logger.info("Blockchain already synced")
      
      {:error, error} ->
        Logger.error("Error syncing blockchain: #{inspect(error)}")
    end

    # Schedule next sync
    Process.send_after(self(), :sync, state.sync_interval)

    # Update state
    {:noreply, %{state | syncing: false, last_synced: DateTime.utc_now()}}
  end

  # Private functions

  defp sync_blockchain(rpc_url) do
    try do
      Sync.sync_blockchain(rpc_url)
    rescue
      e ->
        Logger.error("Error syncing blockchain: #{inspect(e)}")
        {:error, e}
    end
  end
end