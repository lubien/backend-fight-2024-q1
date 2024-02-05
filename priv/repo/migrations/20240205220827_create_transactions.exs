defmodule BackendFight.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :value, :integer
      add :type, :string
      add :description, :string
      add :customer_id, references(:customers, on_delete: :nothing)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:transactions, [:customer_id])
  end
end
