defmodule BackendFightWeb.CustomerControllerTest do
  use BackendFightWeb.ConnCase

  import BackendFight.BankFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show customer" do
    test "renders customer when data is valid", %{conn: conn} do
      %{customer: %{id: id}} = create_customer(%{})
      id |> IO.inspect(label: "#{__MODULE__}:#{__ENV__.line} #{DateTime.utc_now}", limit: :infinity)

      conn = get(conn, ~p"/clientes/#{id}/extrato")

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when customer is not found", %{conn: conn} do
      conn = get(conn, ~p"/clientes/6/extrato")
      assert json_response(conn, 404)
    end
  end

  defp create_customer(_) do
    customer = customer_fixture()
    %{customer: customer}
  end
end
