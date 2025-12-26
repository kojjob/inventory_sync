defmodule InventorySyncWeb.Router do
  use InventorySyncWeb, :router

  import InventorySyncWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InventorySyncWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug InventorySyncWeb.Plugs.ApiAuth
  end

  pipeline :shopify_webhooks do
    # VerifyShopifySignature reads raw body, verifies HMAC, and parses JSON
    plug InventorySyncWeb.Plugs.VerifyShopifySignature
  end

  # Public landing page (no authentication required)
  scope "/", InventorySyncWeb do
    pipe_through [:browser]

    live_session :public,
      root_layout: {InventorySyncWeb.Layouts, :public} do
      live "/", LandingLive, :index
    end
  end

  # Protected routes (authentication required)
  scope "/", InventorySyncWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :default,
      layout: {InventorySyncWeb.Layouts, :app},
      on_mount: InventorySyncWeb.NavHook do
      live "/dashboard", DashboardLive
      live "/products", ProductLive.Index, :index
      live "/products/:id", ProductLive.Show, :show
      live "/channels", ChannelLive.Index, :index
      live "/metrics", MetricsLive, :index
      live "/settings/general", SettingsLive.General, :index
      live "/settings/team", SettingsLive.Team, :index
      live "/activity", ActivityLive.Index, :index
    end
  end

  # Health check endpoints (no authentication required)
  scope "/", InventorySyncWeb do
    pipe_through :api

    get "/health", HealthController, :index
    get "/health/live", HealthController, :liveness
    get "/health/ready", HealthController, :readiness
  end

  # API v1 - REST API with token authentication
  scope "/api/v1", InventorySyncWeb.Api.V1, as: :api_v1 do
    pipe_through [:api, :api_auth]

    resources "/products", ProductController, except: [:new, :edit]
    resources "/channels", ChannelController, except: [:new, :edit]

    # Inventory operations
    get "/inventory", InventoryController, :index
    put "/inventory/:sku", InventoryController, :update

    # Reservations (Phase 2 prerequisite)
    post "/reservations", ReservationController, :create
    delete "/reservations/:id", ReservationController, :release
  end

  # Shopify webhook endpoint with signature verification
  scope "/api", InventorySyncWeb do
    pipe_through :shopify_webhooks

    post "/webhooks/shopify", WebhookController, :shopify
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:inventory_sync, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InventorySyncWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", InventorySyncWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", InventorySyncWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", InventorySyncWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete

    get "/users/reset-password", UserResetPasswordController, :new
    post "/users/reset-password", UserResetPasswordController, :create
    get "/users/reset-password/:token", UserResetPasswordController, :edit
    put "/users/reset-password/:token", UserResetPasswordController, :update

    get "/invitations/accept/:token", TeamInvitationController, :show
  end
end
