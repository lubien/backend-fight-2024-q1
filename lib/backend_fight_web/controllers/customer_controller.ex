defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case Fly.RPC.rpc_primary({Bank, :get_customer_data, [id]}) do
      nil ->
        {:error, :not_found}

      customer_data ->
        render(conn, :show, customer_data: customer_data)
    end
  end
end
