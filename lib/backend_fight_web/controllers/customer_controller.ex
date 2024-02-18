defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  alias BackendFight.Bank

  def show(conn, %{"id" => id}) do
    id =
      case Integer.parse(id) do
        {int, ""} ->
          int

        _ ->
          0
      end

    case Bank.get_customer_data(id) do
      %{} = customer_data ->
        render(conn, :show, customer_data: customer_data)

      _ ->
        {:error, :not_found}
    end
  end
end
