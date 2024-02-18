defmodule BackendFight.Bank do
  @moduledoc """
  The Bank context.
  """

  def get_customer_data(id) do
    [
      [limit, balance, _user, _datetime]
      | other_rows
    ] = Fly.RPC.rpc_primary({TenantMapper, :get_customer_data, [id]})

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
    {:ok, [limit, balance]} = Fly.RPC.rpc_primary({TenantMapper, :insert_transaction, [customer_id, description, type, value]})
    %{limit: limit, balance: balance}
  end
end
