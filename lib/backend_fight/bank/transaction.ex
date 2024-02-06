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
  def changeset(transaction, attrs, customer_id) do
    transaction
    |> cast(%{customer_id: customer_id}, [:customer_id])
    |> cast(attrs, [:value, :type, :description, :customer_id])
    |> validate_required([:value, :type, :description, :customer_id])
    |> foreign_key_constraint(:customer_id)
  end

  def validate_balance(changeset, balance, limit) do
    validate_change(changeset, :value, fn :value, value ->
      type = get_change(changeset, :type)
      if type == :d && (balance - value) < -limit do
        [value: "value #{(balance - value)} cannot be less than #{-limit}"]
      else
        []
      end
    end)
  end
end
