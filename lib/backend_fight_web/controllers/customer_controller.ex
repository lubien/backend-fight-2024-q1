defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  # alias BackendFight.Bank

  def show(_conn, %{"id" => _id}) do
    # case Bank.get_customer_data(id) do
    #   %{} = customer_data ->
    #     render(conn, :show, customer_data: customer_data)

    #   _ ->
    #   end
    {:error, :not_found}
  end
end
