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

    TenantSupervisor.create_customer(999, "Warmup", 10_000_000 * 100)
    for _ <- 1..100_000 do
      SqliteServer.insert_transaction(999, "warmup", "d", 100)
    end

    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
end
