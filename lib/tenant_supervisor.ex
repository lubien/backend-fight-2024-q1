defmodule TenantSupervisor do
  @moduledoc """
  Create and supervise tenants by customer ID
  """
  use DynamicSupervisor

  def create_customer(customer_id, name, limit) do
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, %{
      id: String.to_atom("customer_tenant_#{customer_id}"),
      start: {SqliteServer, :start_link, [customer_id, name, limit]}
    })
    TenantMapper.add_tenant(customer_id, pid)
    :ok
  end

  # Private API

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
