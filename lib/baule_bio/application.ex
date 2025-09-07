defmodule BauleBio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BauleBioWeb.Telemetry,
      BauleBio.Repo,
      {DNSCluster, query: Application.get_env(:baule_bio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BauleBio.PubSub},
      # Start a worker by calling: BauleBio.Worker.start_link(arg)
      # {BauleBio.Worker, arg},
      # Start to serve requests, typically the last entry
      BauleBioWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BauleBio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BauleBioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
