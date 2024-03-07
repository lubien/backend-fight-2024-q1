defmodule BackendFight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    first_chilren = [
      {Fly.RPC, []},
      {Task.Supervisor, name: BackendFight.QuerySupervisor},
    ]

    extra_children =
      if Fly.RPC.is_primary?() do
        [
          Supervisor.child_spec({SqliteServer, [1, "Jonathan", 1_000 * 100]}, id: :customer_1),
          Supervisor.child_spec({SqliteServer, [2, "Joseph", 800 * 100]}, id: :customer_2),
          Supervisor.child_spec({SqliteServer, [3, "Jotaro", 10_000 * 100]}, id: :customer_3),
        ]
      else
        [
          Supervisor.child_spec({SqliteServer, [4, "Josuke", 100_000 * 100]}, id: :customer_4),
          Supervisor.child_spec({SqliteServer, [5, "Giorno", 5_000 * 100]}, id: :customer_5),
        ]
      end

    cluster_opts = [query: Application.get_env(:backend_fight, :dns_cluster_query) || :ignore]

    cluster_opts =
      if System.get_env("USE_DNS_CLUSTER_RESOLVER") do
        Keyword.put(cluster_opts, :resolver, BackendFight.DNSClusterResolver)
      else
        cluster_opts
      end

    children = first_chilren ++ extra_children ++ [
      {DNSCluster, cluster_opts},
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
end
