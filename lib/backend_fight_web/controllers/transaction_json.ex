defmodule BackendFightWeb.TransactionJSON do
  @doc """
  Renders a single transaction.
  """
  def show(%{customer: customer}) do
    %{
      "limite" => customer.limit,
      "saldo" => customer.balance
    }
  end
end
