defmodule TenantStarter do
  @moduledoc """
  This is just a hacky way to create customers bootup for this event.
  We don't need an agent honestly
  """
  use Agent

  def start_link(_opts) do
    customers = [
      [1_000 * 100, "Jonathan"],
      [800 * 100, "Joseph"],
      [10_000 * 100, "Jotaro"],
      [100_000 * 100, "Josuke"],
      [5_000 * 100, "Giorno"]
    ]
    for {[limit, name], index} <- Enum.with_index(customers) do
      TenantSupervisor.create_customer(index + 1, name, limit)
    end

    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
end
