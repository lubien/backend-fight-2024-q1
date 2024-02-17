defmodule BackendFightWeb.TransactionController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  def create(conn, %{
        "customer_id" => customer_id,
        "descricao" => descricao,
        "tipo" => tipo,
        "valor" => valor
      }) do
        id = case Integer.parse(customer_id) do
          {int, ""} ->
            int
          _ ->
            0
        end
    transaction_params = %{description: descricao, type: tipo, value: valor}

    with %{balance: _total, limit: _limite} = customer_data <- do_create(id, transaction_params) do
      conn
      # yes, that's by the spec 😨
      |> put_status(:ok)
      |> render(:show, customer: customer_data)
    end
  end

  def create(_conn, _params) do
    {:error, :unprocessable_entity}
  end

  def do_create(customer_id, %{description: description, type: type, value: value}) do
    Fly.RPC.rpc_primary(fn ->
      :ok = SqliteServer.insert_transaction(customer_id, description, type, value)
      SqliteServer.get_customer(customer_id)
    end)
  end
end
