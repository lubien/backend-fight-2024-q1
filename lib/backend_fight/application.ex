defmodule BackendFight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    extra_children =
      if Fly.RPC.is_primary?() do
        [
          # BackendFight.Repo,
          # {Ecto.Migrator,
          #  repos: Application.fetch_env!(:backend_fight, :ecto_repos), skip: skip_migrations?()},
          # {BackendFight.CustomerCache, []},
          # {BackendFight.BackCollectorSupervisor, []},
          # {SqliteServer, []}
          {TenantMapper, []},
          {TenantSupervisor, []},
          {TenantStarter, []}
        ]
      else
        []
      end

    children = [
      {Cachex, name: :customer_cache},
      {Fly.RPC, []},
      {DNSCluster,
       resolver: BackendFight.DNSClusterResolver,
       query: Application.get_env(:backend_fight, :dns_cluster_query) || :ignore},
      # Start a worker by calling: BackendFight.Worker.start_link(arg)
      # {BackendFight.Worker, arg},
      # Start to serve requests, typically the last entry
      BackendFightWeb.Endpoint
    ] ++ extra_children

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
  #   System.get_env("MY_REGION") != "primary"
  # end
end
