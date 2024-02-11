defmodule BackendFightWeb.CustomerJSON do
  @doc """
  Renders a single customer.
  """
  def show(%{customer_data: %{saldo: saldo, ultimas_transacoes: ultimas_transacoes}}) do
    %{
      saldo: %{
        limite: saldo.limite,
        total: saldo.total,
        data_extrato: DateTime.utc_now() |> DateTime.to_string()
      },
      ultimas_transacoes: ultimas_transacoes
    }
  end
end
