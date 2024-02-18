defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  alias BackendFight.Bank

  def show(conn, %{"id" => id}) do
    case Bank.get_customer_data(id) do
      %{} = customer_data ->
        render(conn, :show, customer_data: customer_data)

      _ ->
        {:error, :not_found}
    end
  end
end
