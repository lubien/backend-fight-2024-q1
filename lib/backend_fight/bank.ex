defmodule BackendFight.Bank do
  @moduledoc """
  The Bank context.
  """
  @warning_diff_ms 50

  alias BackendFight.BankCollector
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

  alias BackendFight.Bank.Transaction

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction_and_return_customer(customer, attrs) do
    with {:ok, transaction, new_balance} <- create_transaction(customer, attrs) do
      if Application.fetch_env!(:backend_fight, :test?) do
        CustomerCache.clear_all_caches()
        BankCollector.schedule_work_now()
      end
      CustomerCache.get_and_update_customer_cache!(String.to_integer(customer.id), fn found ->
        customer =
          case found do
            %{saldo: _saldo, ultimas_transacoes: _ultimas_transacoes} ->
              found
            nil ->
              Logger.info("❌ CACHE MISS")
              get_customer_data(customer.id)
          end

        %{saldo: saldo, ultimas_transacoes: ultimas_transacoes} = customer
        # Logger.info("🔥 CACHE UPDATE")
        {:commit, %{
          saldo: %{saldo | total: new_balance},
          ultimas_transacoes: Enum.take([%{
            id: transaction.id,
            valor: transaction.value,
            tipo: transaction.type,
            descricao: transaction.description,
            realizada_em: transaction.inserted_at
          } | ultimas_transacoes], 10)
        }}
      end)
    end
  end

  def create_transaction(customer, attrs \\ %{}) do
    s = DateTime.utc_now()

    res = do_create_transaction(customer, attrs)
    # res = {:ok, %Transaction{}}

    diff = DateTime.diff(DateTime.utc_now(), s, :millisecond)
    if diff > @warning_diff_ms do
      Logger.warning("create_transaction #{diff}ms")
    end

    res
  end

  defp do_create_transaction(%{id: customer_id}, attrs) do
    if Application.fetch_env!(:backend_fight, :test?) do
      CustomerCache.clear_all_caches()
    end
    case get_customer_data(customer_id) do
      nil ->
        {:error, :not_found}

      %{saldo: %{limite: limit, total: balance}} ->
        changeset = %Transaction{}
        |> Transaction.changeset(attrs, customer_id)
        |> Transaction.validate_balance(balance, limit)

        case changeset do
          %Ecto.Changeset{valid?: true} ->
            now =
              DateTime.utc_now()
              |> DateTime.truncate(:second)

            data =
              changeset.changes
              |> Map.put(:inserted_at, now)
            BackendFight.BankCollector.collect_transaction(data)

            transaction = Ecto.Changeset.apply_changes(%Ecto.Changeset{changeset | changes: data})
            change = if data.type == :d, do: - data.value, else: data.value
            new_balance = balance + change

            {:ok, transaction, new_balance}

          _ ->
            {:error, changeset}
        end
    end
  end

  def get_customer_balance(customer_id) do
    if Application.fetch_env!(:backend_fight, :test?) do
      :ok = BackendFight.BankCollector.schedule_work_now()
    end
    Repo.get(Customer, customer_id).balance
  end
end
