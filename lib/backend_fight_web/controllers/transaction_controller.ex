defmodule BackendFightWeb.TransactionController do
  use BackendFightWeb, :controller

  # alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def create(conn, %{"customer_id" => _customer_id} = _params) do
    # {:error, :not_found}
    Plug.Conn.send_resp(conn, 404, "Not found")


    # with {:ok, transaction_params} <- Bank.parse_params(params),
    #      %{balance: _total, limit: _limite} = customer_data <-
    #        Bank.create_transaction(customer_id, transaction_params) do
    #   conn
    #   # yes, that's by the spec 😨
    #   |> put_status(:ok)
    #   |> render(:show, customer: customer_data)
    # end
  end

  def create(_conn, _params) do
    {:error, :unprocessable_entity}
  end
end
