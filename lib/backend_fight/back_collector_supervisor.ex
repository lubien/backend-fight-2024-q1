defmodule BackendFight.BackCollectorSupervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children =
      [
        {BackendFight.BankCollector, name: BackendFight.BankCollector},
        {Task.Supervisor, name: BackendFight.BankProcessorSupervisor}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
