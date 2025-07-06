defmodule EthExplorer.Repo do
  use Ecto.Repo,
    otp_app: :eth_explorer,
    adapter: Ecto.Adapters.Postgres
end
