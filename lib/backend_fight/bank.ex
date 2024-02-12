defmodule BackendFight.Bank do
  @moduledoc """
  The Bank context.
  """
  @warning_diff_ms 50

  alias BackendFight.CustomerCache

  import Ecto.Query, warn: false
  require Logger
  alias BackendFight.Bank.Transaction
  alias BackendFight.Repo
  alias BackendFight.Bank.Customer

  def get_customer_data(id) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} ->
        get_customer_data(id)
      _ ->
        nil
    end
  end
  def get_customer_data(id) do
    if Application.fetch_env!(:backend_fight, :test?) do
      do_get_customer_data(id)
    else
      res = CustomerCache.fetch_customer_cache(id, fn key ->
        Logger.info("❌ CACHE MISS")
        case do_get_customer_data(key) do
          nil ->
            {:ignore, nil}

          customer_data ->
            {:commit, customer_data}
        end
      end)

      case res do
        {_case, value} -> value
      end
    end
  end

  def do_get_customer_data(id) do
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

    customer_query = from c in Customer,
      select: %{
        id: c.id,
        valor: c.limit,
        tipo: "tipo",
        descricao: fragment("CAST(? as text)", c.balance),
        realizada_em: "now"
      },
      union_all: ^values_query,
      where: c.id == ^id

    s = DateTime.utc_now()
    res = case Repo.all(customer_query) do
      [%{valor: limite, descricao: saldo} | transactions] ->
        %{
          saldo: %{
            total: String.to_integer(saldo),
            limite: limite,
          },
          ultimas_transacoes:
            transactions
            |> Enum.map(&Map.drop(&1, [:id]))
        }

      [] ->
        nil
    end

    diff = DateTime.diff(DateTime.utc_now(), s, :millisecond)
    if diff > @warning_diff_ms do
      Logger.warning("do_get_customer_data #{diff}ms")
    end

    res
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
  def create_transaction_and_return_customer(customer, attrs) do
    with {:ok, _transaction} <- create_transaction(customer, attrs) do
      do_get_customer_data(customer.id)
    end
  end

  def create_transaction(customer, attrs \\ %{}) do
    s = DateTime.utc_now()

    res = do_create_transaction(customer, attrs)

    diff = DateTime.diff(DateTime.utc_now(), s, :millisecond)
    if diff > @warning_diff_ms do
      Logger.warning("create_transaction #{diff}ms")
    end

    res
  end

  defp do_create_transaction(%{id: customer_id}, attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs, customer_id)
    |> Repo.insert(wait: false)
  rescue
    _e in Ecto.ConstraintError ->
      {:error, :not_found}

    e in Exqlite.Error ->
      case e do
        %{message: "Invalid value" = message} ->
          {:error, %Transaction{}
          |> Transaction.changeset(attrs, customer_id)
          |> Ecto.Changeset.add_error(:value, message)}
      end
  end

  def get_customer_balance(customer_id) do
    Repo.get(Customer, customer_id).balance
  end
end
