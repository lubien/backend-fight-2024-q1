defmodule BackendFight.BankProcessor do
  # alias BackendFight.Bank
  alias BackendFight.Bank.Transaction
  alias BackendFight.Repo

  def run(queue) do
    Enum.into(queue, [])
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all(Transaction, batch)
    end)
  end
end
