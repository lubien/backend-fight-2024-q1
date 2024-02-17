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
end
