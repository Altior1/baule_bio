defmodule BauleBioWeb.Router do
  use BauleBioWeb, :router

  import BauleBioWeb.UtilisateurAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BauleBioWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_utilisateur
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BauleBioWeb do
    pipe_through :browser

    get "/home", PageController, :home
    live "/", HomeLive, :home

    live "/recettes", RecetteLive.Index, :index
    live "/recettes/:id", RecetteLive.Show, :show

    live "/ingredients", Ingredients.Index, :index
    live "/ingredients/:id", Ingredients.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", BauleBioWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:baule_bio, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BauleBioWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BauleBioWeb do
    pipe_through [:browser, :require_authenticated_utilisateur]

    live_session :require_authenticated_utilisateur,
      on_mount: [{BauleBioWeb.UtilisateurAuth, :require_authenticated}] do
      live "/utilisateurs/settings", UtilisateurLive.Settings, :edit
      live "/utilisateurs/settings/confirm-email/:token", UtilisateurLive.Settings, :confirm_email
      live "/recettes/new", RecetteLive.Form, :new
      live "/recettes/:id/edit", RecetteLive.Form, :edit
      live "/ingredients/new", Ingredients.Form, :new
      live "/ingredients/:id/edit", Ingredients.Form, :edit
      live "/admin/recettes", RecetteLive.Admin, :index
      live "/admin/ingredients", Ingredients.Admin, :index
      live "/admin/ingredients/new", Ingredients.AdminForm, :new
      live "/admin/ingredients/:id/edit", Ingredients.AdminForm, :edit
    end

    post "/utilisateurs/update-password", UtilisateurSessionController, :update_password
  end

  scope "/", BauleBioWeb do
    pipe_through [:browser]

    live_session :current_utilisateur,
      on_mount: [{BauleBioWeb.UtilisateurAuth, :mount_current_scope}] do
      live "/utilisateurs/register", UtilisateurLive.Registration, :new
      live "/utilisateurs/log-in", UtilisateurLive.Login, :new
      live "/utilisateurs/log-in/:token", UtilisateurLive.Confirmation, :new
    end

    post "/utilisateurs/log-in", UtilisateurSessionController, :create
    delete "/utilisateurs/log-out", UtilisateurSessionController, :delete
  end
end
