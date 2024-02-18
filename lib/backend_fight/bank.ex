defmodule BackendFight.Bank do
  @moduledoc """
  The Bank context.
  """

  def get_customer_data(id) do
    Fly.RPC.rpc_primary({TenantMapper, :get_customer_data, [id]})
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
    Fly.RPC.rpc_primary(fn ->
      TenantMapper.insert_transaction(customer_id, description, type, value)
    end)
  end
end
