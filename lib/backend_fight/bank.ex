defmodule BackendFight.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias BackendFight.Bank.Transaction
  alias BackendFight.Repo

  alias BackendFight.Bank.Customer

  def get_customer_data(id) do
    values_query = from t in Transaction,
      select: %{
        id: t.id,
        valor: t.value,
        tipo: t.type,
        descricao: t.description,
        realizada_em: t.inserted_at
      },
      order_by: [desc: t.inserted_at, desc: t.id],
      limit: 10

    balance_subquery = query_get_balance(id)

    customer_query = from c in Customer,
      select: %{
        id: c.id,
        valor: c.limit,
        tipo: "tipo",
        descricao: subquery(balance_subquery),
        realizada_em: "now"
      },
      union_all: ^values_query,
      where: c.id == ^id

    case Repo.all(customer_query) do
      [%{valor: limite, descricao: saldo} | transactions] ->
        %{
          saldo: %{
            total: saldo,
            limite: limite,
            data_extrato: DateTime.utc_now() |> DateTime.to_string(),
          },
          ultimas_transacoes:
            transactions
            |> Enum.map(&Map.drop(&1, [:id]))
        }

      [] ->
        nil
    end
  end

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers()
      [%Customer{}, ...]

  """
  def list_customers do
    Repo.all(Customer)
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id), do: Repo.get!(Customer, id)

  @doc """
  Gets a single customer or nil

  ## Examples

      iex> get_customer(123)
      %Customer{}

      iex> get_customer(456)
      ** nil

  """
  def get_customer(id), do: Repo.get(Customer, id)

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(%{field: value})
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete_customer(customer)
      {:ok, %Customer{}}

      iex> delete_customer(customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer(%Customer{} = customer) do
    Repo.delete(customer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  alias BackendFight.Bank.Transaction

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(Transaction)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(%{id: customer_id}, attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs, customer_id)
    |> Repo.insert()
  rescue
    _e in Ecto.ConstraintError ->
      {:error, :not_found}

    _e in Exqlite.Error ->
      {:error, %Transaction{}
      |> Transaction.changeset(attrs, customer_id)
      |> Ecto.Changeset.add_error(:customer_id, "Invalid balance")}
  end

  def get_customer_balance(customer_id) do
    Repo.get(Customer, customer_id).balance
  end

  defp query_get_balance(customer_id) do
    subquery_balance = from t in Transaction,
      where: t.customer_id == ^customer_id,
      select: sum(fragment("case when ? = 'c' then ? else ? end", t.type, t.value, -t.value))

    from c in Customer,
      where: c.id == ^customer_id,
      select: fragment("coalesce(?, 0)", subquery(subquery_balance))
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs, nil)
  end
end
