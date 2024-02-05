defmodule BackendFightWeb.TransactionControllerTest do
  use BackendFightWeb.ConnCase

  @create_attrs %{
    description: "some description",
    type: :c,
    value: 42
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create transaction" do
    test "renders transaction when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/clientes/%{customer_id}/transacoes", transaction: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]

      # conn = get(conn, ~p"/clientes/#{id}")

      # assert %{
      #          "id" => ^id,
      #          "description" => "some description",
      #          "type" => "c",
      #          "value" => 42
      #        } = json_response(conn, 200)["data"]
    end

    # test "renders errors when data is invalid", %{conn: conn} do
    #   conn = post(conn, ~p"/clientes", transaction: @invalid_attrs)
    #   assert json_response(conn, 422)["errors"] != %{}
    # end
  end
end
