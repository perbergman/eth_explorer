defmodule EthExplorerWeb.Router do
  use EthExplorerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EthExplorerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EthExplorerWeb do
    pipe_through :browser

    # Home page
    live "/", HomeLive.Index, :index
    
    # Blocks
    live "/blocks", BlockLive.Index, :index
    live "/blocks/:id", BlockLive.Show, :show
    
    # Transactions
    live "/tx/:id", TransactionLive.Show, :show
    
    # Addresses
    live "/address/:id", AddressLive.Show, :show
    
    # Mint tokens
    live "/mint", MintLive.Index, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", EthExplorerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:eth_explorer, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EthExplorerWeb.Telemetry
    end
  end
end
