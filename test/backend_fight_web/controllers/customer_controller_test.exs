defmodule BackendFightWeb.CustomerControllerTest do
  use BackendFightWeb.ConnCase

  alias BackendFight.Bank
  alias BackendFight.CustomerCache
  import BackendFight.BankFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show customer" do
    test "renders customer when customer is fresh", %{conn: conn} do
      customer = customer_fixture(%{limit: 123})
      assert Bank.get_customer_balance(customer.id) == 0
      CustomerCache.clear_all_caches()
      conn = get(conn, ~p"/clientes/#{customer.id}/extrato")

      assert %{
               "saldo" => %{
                 "total" => 0,
                 "limite" => 123
               },
               "ultimas_transacoes" => []
             } = json_response(conn, 200)
    end

    test "renders customer when data is valid", %{conn: conn} do
      customer = customer_fixture(%{limit: 1000})
      assert Bank.get_customer_balance(customer.id) == 0

      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade 1",
        tipo: "d",
        valor: 200
      })
      assert %{"limite" => 1000, "saldo" => -200} = json_response(conn, 200)
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade 2",
        tipo: "c",
        valor: 100
      })
      assert %{"limite" => 1000, "saldo" => -100} = json_response(conn, 200)
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade 3",
        tipo: "d",
        valor: 700
      })
      assert %{"limite" => 1000, "saldo" => -800} = json_response(conn, 200)

      assert Bank.get_customer_balance(customer.id) == -800

      conn = get(conn, ~p"/clientes/#{customer.id}/extrato")

      assert %{
               "saldo" => %{
                 "total" => -800,
                 "limite" => 1000
               },
               "ultimas_transacoes" => [
                 %{
                   "descricao" => "trade 3",
                   "tipo" => "d",
                   "valor" => 700
                 },
                 %{
                   "descricao" => "trade 2",
                   "tipo" => "c",
                   "valor" => 100
                 },
                 %{
                   "descricao" => "trade 1",
                   "tipo" => "d",
                   "valor" => 200
                 }
               ]
             } = json_response(conn, 200)
    end

    test "renders errors when customer is not found", %{conn: conn} do
      conn = get(conn, ~p"/clientes/600/extrato")
      assert json_response(conn, 404)
    end
  end
end
