defmodule BackendFight.BankFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BackendFight.Bank` context.
  """

  @doc """
  Generate a customer.
  """
  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        limit: 42,
        name: "some name",
        balance: 0
      })
      |> BackendFight.Bank.create_customer()

    customer
  end

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        description: "trade",
        type: :c,
        value: 42
      })
      |> BackendFight.Bank.create_transaction()

    transaction
  end
end
