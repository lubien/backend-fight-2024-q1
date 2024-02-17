defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => id}) do
    id =
      case Integer.parse(id) do
        {int, ""} ->
          int

        _ ->
          0
      end

    case get_customer(id) do
      %{} = customer_data ->
        render(conn, :show, customer_data: customer_data)

      _ ->
        {:error, :not_found}
    end
  end

  def get_customer(id) do
    Fly.RPC.rpc_primary({SqliteServer, :get_customer_data, [id]})
  end
end
