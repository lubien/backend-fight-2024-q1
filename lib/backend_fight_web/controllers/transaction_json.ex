defmodule BackendFightWeb.TransactionJSON do
  alias BackendFight.Bank.Transaction

  @doc """
  Renders a list of transactions.
  """
  def index(%{transactions: transactions}) do
    %{data: for(transaction <- transactions, do: data(transaction))}
  end

  @doc """
  Renders a single transaction.
  """
  def show(%{transaction: transaction}) do
    %{data: data(transaction)}
  end

  defp data(%Transaction{} = transaction) do
    %{
      id: transaction.id,
      value: transaction.value,
      type: transaction.type,
      description: transaction.description
    }
  end
end
