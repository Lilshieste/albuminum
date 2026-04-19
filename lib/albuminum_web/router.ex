defmodule AlbuminumWeb.Router do
  use AlbuminumWeb, :router

  import AlbuminumWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AlbuminumWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlbuminumWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Public album view (no auth required)
    live "/view/:token", AlbumLive.PublicShow, :show
  end

  # Protected album routes - require authentication
  scope "/", AlbuminumWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{AlbuminumWeb.UserAuth, :require_authenticated_user}] do
      live "/albums", AlbumLive.Index, :index
      live "/albums/new", AlbumLive.Form, :new
      live "/albums/:id", AlbumLive.Show, :show
      live "/albums/:id/edit", AlbumLive.Form, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AlbuminumWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:albuminum, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AlbuminumWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AlbuminumWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  # Google OAuth routes - login (unauthenticated only)
  scope "/auth", AlbuminumWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/google", GoogleAuthController, :request
  end

  # Google OAuth - connect Photos (authenticated only)
  scope "/auth", AlbuminumWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/google/photos", GoogleAuthController, :connect_photos
  end

  # Google OAuth callback - works for both flows
  scope "/auth", AlbuminumWeb do
    pipe_through [:browser]

    get "/google/callback", GoogleAuthController, :callback
  end

  scope "/", AlbuminumWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", AlbuminumWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
