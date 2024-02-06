defmodule BackendFightWeb.TransactionControllerTest do
  use BackendFightWeb.ConnCase

  import BackendFight.BankFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create transaction" do
    test "renders transaction when data is valid", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", transaction: %{
        description: "trade",
        type: :d,
        value: 42
      })
      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", transaction: %{
        description: "trade",
        type: :d,
        value: 101
      })
      assert json_response(conn, 422)
    end
  end
end
