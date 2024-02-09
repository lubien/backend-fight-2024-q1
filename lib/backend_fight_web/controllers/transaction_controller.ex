defmodule BackendFightWeb.TransactionController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank
  alias BackendFight.Bank.Transaction

  action_fallback BackendFightWeb.FallbackController

  def create(conn, %{"customer_id" => customer_id, "transaction" => transaction_params}) do
    case Bank.get_customer(customer_id) do
      nil ->
        {:error, :not_found}
      customer ->
        with {:ok, %Transaction{} = _transaction} <- Bank.create_transaction(customer, transaction_params) do
          balance = Bank.get_customer_balance(customer.id)

          conn
          |> put_status(:ok) # yes, that's by the spec 😨
          |> render(:show, customer: customer, balance: balance)
        end
    end
  end
end
