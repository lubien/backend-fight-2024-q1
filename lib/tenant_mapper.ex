defmodule TenantMapper do
  @doc """
  Get tenant conenction by ID
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_tenant(id, pid) do
    Agent.update(__MODULE__, &Map.put_new(&1, id, pid))
  end

  def get_tenant(id) do
    Agent.get(__MODULE__, &Map.get(&1, id))
  end

  def insert_transaction(customer_id, description, type, value) do
    if pid = get_tenant(customer_id) do
      SqliteServer.insert_transaction(pid, description, type, value)
    else
      {:error, :not_found}
    end
  end

  def get_customer_data(customer_id) do
    if pid = get_tenant(customer_id) do
      SqliteServer.get_customer_data(pid)
    else
      {:error, :not_found}
    end
  end

  def get_customer(customer_id) do
    if pid = get_tenant(customer_id) do
      SqliteServer.get_customer(pid)
    else
      {:error, :not_found}
    end
  end
end
