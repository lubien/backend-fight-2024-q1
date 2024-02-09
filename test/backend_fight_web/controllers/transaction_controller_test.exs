defmodule BackendFightWeb.TransactionControllerTest do
  use BackendFightWeb.ConnCase

  import BackendFight.BankFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create transaction" do
    test "renders transaction when data is valid", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade",
        tipo: :d,
        valor: 42
      })
      assert %{"limite" => 100, "saldo" => -42} = json_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade",
        tipo: :d,
        valor: 101
      })
      assert json_response(conn, 422)
    end
  end
end
