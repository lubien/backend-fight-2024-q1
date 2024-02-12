defmodule BackendFight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
require Logger

  use Application

  @impl true
  def start(_type, _args) do
    if Fly.RPC.is_primary?() do
      Task.async(fn ->
        :timer.sleep(3000)
        try do
          Logger.info("seeding prod, dont do this at home kids")
          BackendFight.Release.prod_seed
        rescue
          e in RuntimeError -> Logger.error(e)
        end
      end)
    end

    children = [
      {Litefs, Application.get_env(:backend_fight, BackendFight.Repo.Local)},
      BackendFight.Repo.Local,
      {Cachex, name: :customer_cache},
      {Fly.RPC, []},
      {DNSCluster,
       resolver: BackendFight.DNSClusterResolver,
       query: Application.get_env(:backend_fight, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BackendFight.PubSub},
      {BackendFight.CustomerCache, []},
      # Start a worker by calling: BackendFight.Worker.start_link(arg)
      # {BackendFight.Worker, arg},
      # Start to serve requests, typically the last entry
      BackendFightWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BackendFight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BackendFightWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # defp skip_migrations?() do
  #   # By default, sqlite migrations are run when using a release
  #   System.get_env("RELEASE_NAME") != nil
  # end
end
