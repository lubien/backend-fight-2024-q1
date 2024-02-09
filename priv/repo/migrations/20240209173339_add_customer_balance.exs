defmodule BackendFight.Repo.Migrations.AddCustomerBalance do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :balance, :integer, null: false, default: 0
    end
  end
end
