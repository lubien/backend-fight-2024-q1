defmodule BackendFightWeb.TransactionJSON do
  @doc """
  Renders a single transaction.
  """
  def show(%{customer: customer, balance: balance}) do
    %{
      "limite" => customer.limit,
      "saldo" => balance
    }
  end
end
