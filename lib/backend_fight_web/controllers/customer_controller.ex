defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => _id}) do
    # if customer_data = get_customer(id) do
      render(conn, :show, customer_data: %{
        saldo: %{total: 1, limite: 1}, ultimas_transacoes: []
      })
    # else
    #   {:error, :not_found}
    # end
  end

  def get_customer(id) do
    Fly.RPC.rpc_primary({Bank, :get_customer_data, [id]})
  end
end
