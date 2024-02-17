defmodule TenantStarter do
  @moduledoc """
  This is just a hacky way to create customers bootup for this event.
  We don't need an agent honestly
  """
  require Logger
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
    prev = System.monotonic_time()
    Logger.info("[#{DateTime.utc_now}] Warming up before starting server")
    Stream.resource(fn -> :ok end, fn _ ->
        time = System.monotonic_time()
        seconds = (time - prev)/1_000_000_000
        if seconds >= 15 do
          {:halt, :ok}
        else
          {[:ok], :ok}
        end
      end,
      fn _ -> :ok end
    )
    |> Enum.each(fn _ ->
      SqliteServer.insert_transaction(999, "warmup", "d", 100)
    end)
    Logger.info("[#{DateTime.utc_now}] Warmed up")

    {:ok, _pid} = DynamicSupervisor.start_child(TenantSupervisor, %{
      id: :endpoint,
      start: {BackendFightWeb.Endpoint, :start_link, []}
    })

    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
end
