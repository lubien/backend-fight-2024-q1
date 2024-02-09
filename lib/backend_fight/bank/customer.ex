defmodule BackendFight.Bank.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :limit, :integer
    field :name, :string
    field :balance, :integer, default: 0
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :limit])
    |> validate_required([:name, :limit])
  end
end
