defmodule BackendFightWeb.CustomerController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank

  action_fallback BackendFightWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case Bank.get_customer(id) do
      nil -> {:error, :not_found}
      customer -> render(conn, :show, customer: customer)
    end
  end
end
