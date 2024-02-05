defmodule BackendFight.Bank.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :description, :string
    field :type, Ecto.Enum, values: [:c, :d]
    field :value, :integer

    belongs_to :customer, BackendFight.Bank.Customer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:value, :type, :description])
    |> validate_required([:value, :type, :description])
  end
end
