defmodule BackendFightWeb.CustomerControllerTest do
  use BackendFightWeb.ConnCase

  alias BackendFight.Bank
  alias BackendFight.Bank.Transaction
  import BackendFight.BankFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show customer" do
    test "renders customer when data is valid", %{conn: conn} do
      customer = customer_fixture(%{limit: 1000})
      assert Bank.get_customer_balance(customer.id) == 0

      assert {:ok, %Transaction{} = _transaction} =
               Bank.create_transaction(customer, %{
                 description: "trade",
                 type: "d",
                 value: 200
               })

      assert {:ok, %Transaction{} = _transaction} =
               Bank.create_transaction(customer, %{
                 description: "trade",
                 type: "c",
                 value: 100
               })

      assert {:ok, %Transaction{} = _transaction} =
               Bank.create_transaction(customer, %{
                 description: "trade",
                 type: "d",
                 value: 700
               })

      assert Bank.get_customer_balance(customer.id) == -800

      conn = get(conn, ~p"/clientes/#{customer.id}/extrato")

      assert %{
               "saldo" => %{
                 "total" => -800,
                 "limite" => 1000
               },
               "ultimas_transacoes" => [
                 %{
                   "descricao" => "trade",
                   "tipo" => "d",
                   "value" => 700
                 },
                 %{
                   "descricao" => "trade",
                   "tipo" => "c",
                   "value" => 100
                 },
                 %{
                   "descricao" => "trade",
                   "tipo" => "d",
                   "value" => 200
                 }
               ]
             } = json_response(conn, 200)
    end

    test "renders errors when customer is not found", %{conn: conn} do
      conn = get(conn, ~p"/clientes/6/extrato")
      assert json_response(conn, 404)
    end
  end
end
