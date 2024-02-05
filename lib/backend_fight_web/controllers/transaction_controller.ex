defmodule BackendFightWeb.TransactionController do
  use BackendFightWeb, :controller

  alias BackendFight.Bank
  alias BackendFight.Bank.Transaction

  action_fallback BackendFightWeb.FallbackController

  def create(conn, %{"transaction" => transaction_params}) do
    with {:ok, %Transaction{} = transaction} <- Bank.create_transaction(transaction_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", ~p"/api/transactions/#{transaction}")
      |> render(:show, transaction: transaction)
    end
  end
end
