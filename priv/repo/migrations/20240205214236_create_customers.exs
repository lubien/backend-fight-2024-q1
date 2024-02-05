defmodule BackendFight.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string, null: false
      add :limit, :integer, null: false
    end
  end
end
