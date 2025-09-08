defmodule BauleBioWeb.Router do
  use BauleBioWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BauleBioWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BauleBioWeb do
    pipe_through :browser

    get "/home", PageController, :home
    live "/", HomeLive, :home

    live "/recettes", RecetteLive.Index, :index
    live "/recettes/new", RecetteLive.Form, :new
    live "/recettes/:id", RecetteLive.Show, :show
    live "/recettes/:id/edit", RecetteLive.Form, :edit

    live "/ingredients", Ingredients.Index, :index
    live "/ingredients/new", Ingredients.Form, :new
    live "/ingredients/:id/edit", Ingredients.Form, :edit
    live "/ingredients/:id/delete", Ingredients.Delete, :delete
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
end
