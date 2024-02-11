defmodule BackendFightWeb.TransactionController do
  use BackendFightWeb, :controller

  alias BackendFight.CustomerCache
  alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def create(conn, %{
        "customer_id" => customer_id,
        "descricao" => descricao,
        "tipo" => tipo,
        "valor" => valor
      }) do
    transaction_params = %{description: descricao, type: tipo, value: valor}

    with %{saldo: saldo} = customer_data <- do_create(customer_id, transaction_params) do
      CustomerCache.set_customer_cache(customer_id, customer_data)
      conn
      # yes, that's by the spec 😨
      |> put_status(:ok)
      |> render(:show, customer: %{limit: saldo.limite, balance: saldo.total})
    end
  end

  def create(_conn, _params) do
    {:error, :unprocessable_entity}
  end

  def do_create(customer_id, transaction_params) do
    Fly.RPC.rpc_primary(fn ->
      Bank.create_transaction_and_return_customer(%{id: customer_id}, transaction_params)
    end)
  end
end
