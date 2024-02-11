defmodule BackendFight.BankCollector do
  use GenServer

  alias BackendFight.BankProcessor

  # Client Functions
  def start_link(opts) do
    queue = Qex.new()
    GenServer.start_link(__MODULE__, queue, opts)
  end

  def collect_transaction(attrs) do
    GenServer.cast(__MODULE__, {:push, attrs})
  end

  def schedule_work_now() do
    GenServer.call(__MODULE__, :work_now)
  end

  # Server Callbacks
  def init(queue) do
    schedule_work()
    {:ok, queue}
  end

  defp schedule_work do
    # Process the queue every 10 seconds
    Process.send_after(self(), :work, 10_000)
  end

  def handle_info(:work, queue) do
    {:noreply, work_now(queue)}
  end

  defp persist_queue(queue) do
    Task.Supervisor.start_child(BackendFight.BankProcessorSupervisor, BankProcessor, :run, [queue])
  end

  defp work_now(queue) do
    persist_queue(queue)

    # Reinitialize the queue
    queue = Qex.new()

    # Schedule the next time we process the queue
    schedule_work()

    # Return our state
    queue
  end

  def handle_cast({:push, item}, queue) do
    queue = Qex.push(queue, item)
    {:noreply, queue}
  end

  def handle_call(:work_now, _from, queue) do
    {:reply, :ok, work_now(queue)}
  end
end
