defmodule BackendFightWeb.TransactionController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank
  alias BackendFight.Bank.Transaction

  action_fallback BackendFightWeb.FallbackController

  def create(conn, %{
        "customer_id" => customer_id,
        "descricao" => descricao,
        "tipo" => tipo,
        "valor" => valor
      }) do
    transaction_params = %{description: descricao, type: tipo, value: valor}

    with {:ok, customer} <- do_create(customer_id, transaction_params) do
      conn
      # yes, that's by the spec 😨
      |> put_status(:ok)
      |> render(:show, customer: customer, balance: customer.balance)
    end
  end

  def create(_conn, _params) do
    {:error, :unprocessable_entity}
  end

  def do_create(customer_id, transaction_params) do
    Fly.RPC.rpc_primary(fn ->
      with {:ok, %Transaction{} = _transaction} <-
             Bank.create_transaction(%{id: customer_id}, transaction_params) do
        customer = Bank.get_customer(customer_id)
        {:ok, customer}
      end
    end)
  end
end
