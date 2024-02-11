defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank
  alias BackendFight.CustomerCache

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case get_customer(id) do
      nil ->
        {:error, :not_found}

      customer_data ->
        render(conn, :show, customer_data: customer_data)
    end
  end

  def get_customer(id) do
    if data = CustomerCache.get_customer_cache(id) do
      data
    else
      Fly.RPC.rpc_region(Bank.region_for_customer(id), {Bank, :get_customer_data, [id]})
    end
  end
end
