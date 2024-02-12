defmodule BackendFight.Repo.Migrations.RunSeeds do
  use Ecto.Migration

  def up do
    BackendFight.Repo.insert!(%BackendFight.Bank.Customer{
      id: 1,
      limit: 1_000 * 100,
      name: "Jonathan"
    })
    BackendFight.Repo.insert!(%BackendFight.Bank.Customer{
      id: 2,
      limit: 800 * 100,
      name: "Joseph"
    })
    BackendFight.Repo.insert!(%BackendFight.Bank.Customer{
      id: 3,
      limit: 10_000 * 100,
      name: "Jotaro"
    })
    BackendFight.Repo.insert!(%BackendFight.Bank.Customer{
      id: 4,
      limit: 100_000 * 100,
      name: "Josuke"
    })
    BackendFight.Repo.insert!(%BackendFight.Bank.Customer{
      id: 5,
      limit: 5_000 * 100,
      name: "Giorno"
    })

  end

  def down do
  end
end
