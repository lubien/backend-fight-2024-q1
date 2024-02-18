defmodule BackendFight.Bank do
  @moduledoc """
  The Bank context.
  """

  def get_customer_data(id) do
    with [
           [limit, balance, _user, _datetime]
           | other_rows
         ] <- rpc_tenant(id, {SqliteServer, :get_customer_data, [id]}) do
      ultimas_transacoes =
        Enum.map(other_rows, fn [value, description, type, inserted_at] ->
          %{
            valor: value,
            descricao: description,
            tipo: type,
            realidada_em: DateTime.from_unix!(inserted_at, :millisecond)
          }
        end)

      %{
        saldo: %{limite: limit, total: balance},
        ultimas_transacoes: ultimas_transacoes
      }
    end
  end

  def parse_params(%{"descricao" => description, "tipo" => type, "valor" => value})
      when type in ["c", "d"] and is_binary(description) and is_integer(value) do
    valid_length? = String.length(description) >= 1 && String.length(description) <= 10

    if valid_length? do
      {:ok, %{description: description, type: type, value: value}}
    else
      {:error, :unprocessable_entity}
    end
  end

  def parse_params(_params) do
    {:error, :unprocessable_entity}
  end

  def create_transaction(customer_id, %{description: description, type: type, value: value}) do
    with {:ok, [limit, balance]} <-
           rpc_tenant(
             customer_id,
             {SqliteServer, :insert_transaction, [customer_id, description, type, value]}
           ) do
      %{limit: limit, balance: balance}
    end
  end

  def rpc_tenant(customer_id, mfa) do
    # For local tests
    if Fly.RPC.my_region() == "local" do
      Fly.RPC.rpc_primary(mfa)
    else
      region =
        if customer_id in [1, 2, 3, "1", "2", "3"] do
          "primary"
        else
          "replica"
        end

      Fly.RPC.rpc_region(region, mfa)
    end
  end
end
