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
        name: "some name"
      })
      |> BackendFight.Bank.create_customer()

    customer
  end
end
