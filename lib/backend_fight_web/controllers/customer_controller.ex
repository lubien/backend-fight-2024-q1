defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case Fly.RPC.rpc_region(Bank.region_for_customer(id), {Bank, :get_customer_data, [id]}) do
      nil ->
        {:error, :not_found}

      customer_data ->
        render(conn, :show, customer_data: customer_data)
    end
  end
end
