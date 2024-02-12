defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => id}) do
    if customer_data = get_customer(id) do
      render(conn, :show, customer_data: customer_data)
    else
      {:error, :not_found}
    end
  end

  def get_customer(id) do
    Fly.RPC.rpc_primary({Bank, :get_customer_data, [id]})
  end
end
