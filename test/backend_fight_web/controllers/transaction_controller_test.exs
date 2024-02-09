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

    test "renders errors when value is non integer", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade",
        tipo: "d",
        valor: 1.2
      })
      assert json_response(conn, 422)
    end

    test "renders errors when type in unknown", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade",
        tipo: "x",
        valor: 1
      })
      assert json_response(conn, 422)
    end


    test "renders errors when description is long", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "trade muito mais que 10",
        tipo: "d",
        valor: 1
      })
      assert json_response(conn, 422)
    end

    test "renders errors when description is weird", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: "",
        tipo: "c",
        valor: 1
      })
      assert json_response(conn, 422)
    end

    test "renders errors when description is null", %{conn: conn} do
      customer = customer_fixture(%{limit: 100})
      conn = post(conn, ~p"/clientes/#{customer.id}/transacoes", %{
        descricao: nil,
        tipo: "c",
        valor: 1
      })
      assert json_response(conn, 422)
    end

    test "renders errors when customer does not exist", %{conn: conn} do
      conn = post(conn, ~p"/clientes/100/transacoes", %{
        descricao: "peguei",
        tipo: "c",
        valor: 1
      })
      assert json_response(conn, 404)
    end
  end
end
