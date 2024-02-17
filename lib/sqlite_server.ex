defmodule SqliteServer do
  use GenServer

  def insert_customer(name, limit) do
    GenServer.call(__MODULE__, {:insert_customer, {name, limit}})
  end

  def insert_transaction(customer_id, description, type, value) do
    if pid = TenantMapper.get_tenant(customer_id) do
      GenServer.call(pid, {:insert_transaction, {description, type, value}})
    else
      :ok
    end
  end

  def get_customer_data(customer_id) do
    if pid = TenantMapper.get_tenant(customer_id) do
      GenServer.call(pid, :get_customer_data)
    else
      :ok
    end
  end

  def get_customer(customer_id) do
    if pid = TenantMapper.get_tenant(customer_id) do
      GenServer.call(pid, :get_customer)
    else
      :ok
    end
  end

  # Private API
  def start_link(customer_id, name, limit) do
    GenServer.start_link(__MODULE__, [customer_id, name, limit])
  end

  def init([customer_id, name, limit]) do
    path = "#{System.get_env("DATABASE_PATH")}/#{customer_id}.db"
    {:ok, conn} = Exqlite.Sqlite3.open(path)
    do_init_db(conn)
    do_insert_customer(conn, name, limit)
    {:ok, insert_transaction_stmt} = Exqlite.Sqlite3.prepare(conn, """
      insert into transactions (description, \"type\", \"value\") values (?1, ?2, ?3)
    """)
    {:ok, get_customer_stmt} = Exqlite.Sqlite3.prepare(conn, """
    select "limit", balance from customers limit 1
    """)
    {:ok, get_customer_data_stmt} = Exqlite.Sqlite3.prepare(conn, """
      select
        "limit" as "valor",
        balance as "descricao",
        'user' as "tipo",
        'now' as "realizada_em"
      from customers

      UNION ALL

      select
        "value" as "valor",
        description as "descricao",
        "type" as "tipo",
        inserted_at as "realizada_em"
      from
        transactions
      ORDER BY
        inserted_at desc
      LIMIT 11
    """)
    {:ok, %{
      conn: conn,
      insert_transaction_stmt: insert_transaction_stmt,
      get_customer_stmt: get_customer_stmt,
      get_customer_data_stmt: get_customer_data_stmt
    }}
  end

  def handle_call({:insert_customer, {name, limit}}, _from, %{conn: conn} = state) do
    :ok = do_insert_customer(conn, name, limit)
    {:reply, :ok, state}
  end

  def handle_call({:insert_transaction, {description, type, value}}, _from, %{conn: conn, insert_transaction_stmt: statement} = state) do
    :ok = Exqlite.Sqlite3.bind(conn, statement, [description, type, value])
    Exqlite.Sqlite3.step(conn, statement)
    {:reply, :ok, state}
  rescue
    RuntimeError ->
      {:reply, :ok, state}
  end

  def handle_call(:get_customer_data, _from, %{conn: conn, get_customer_data_stmt: statement} = state) do
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])
    {:row, [limit, balance, _user, _datetime]} = Exqlite.Sqlite3.step(conn, statement)
    ultimas_transacoes =
      1..100000
      |> Enum.reduce_while([], fn _el, acc ->
        case Exqlite.Sqlite3.step(conn, statement) do
          {:row, [value, description, type, inserted_at]} ->
            item = %{
              valor: value,
              descricao: description,
              tipo: type,
              realidada_em: DateTime.from_unix!(inserted_at, :millisecond)
            }
            {:cont, [item | acc]}

          _ ->
            {:halt, acc}
        end
      end)

    {:reply, %{
      saldo: %{limite: limit, total: balance},
      ultimas_transacoes: Enum.reverse(ultimas_transacoes)
    }, state}
  rescue
    RuntimeError ->
      {:reply, :ok, state}
  end

  def handle_call(:get_customer, _from, %{conn: conn, get_customer_stmt: statement} = state) do
    :ok = Exqlite.Sqlite3.bind(conn, statement, [])
    {:row, [limit, balance]} = Exqlite.Sqlite3.step(conn, statement)
    {:reply, %{limit: limit, balance: balance}, state}
  rescue
    RuntimeError ->
      {:reply, :ok, state}
  end

  defp do_init_db(conn) do
    :ok = Exqlite.Sqlite3.execute(conn, """
      create table if not exists customers (id integer primary key, name text, \"limit\" integer, balance integer not null)
    """)
    :ok = Exqlite.Sqlite3.execute(conn, """
    create table if not exists transactions (
      id integer primary key,
      description text,
      customer_id integer,
      type text,
      value integer,
      inserted_at integer default (CAST(ROUND((julianday('now') - 2440587.5)*86400000) As INTEGER)),
      foreign key (customer_id) references customers(id))
    """)
    # :ok = Exqlite.Sqlite3.execute(conn, "create index transactions_customer_id ON transactions(customer_id)")
    :ok = Exqlite.Sqlite3.execute(conn, "create index transactions_inserted_at_desc ON transactions(inserted_at desc)")
    :ok = Exqlite.Sqlite3.execute(conn, """
    CREATE TRIGGER if not exists validate_balance_before_insert_transaction
    BEFORE INSERT ON transactions
    BEGIN
      SELECT CASE WHEN (select balance from customers) + (
        case when NEW.type = 'c' then +NEW.value else -NEW.value end
      ) < -(select "limit" from customers) THEN
        RAISE (ABORT, 'Invalid value')
      END;

      UPDATE customers
      SET balance = customers.balance + (case when NEW.type = 'c' then +NEW.value else -NEW.value end);
    END;
    """)

    :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA synchronous = OFF")
    :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA journal_mode = MEMORY")
    :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA threads = 32")
    # :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA foreign_keys = ON")
  end

  defp do_insert_customer(conn, name, limit) do
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "insert into customers (\"limit\", name, balance) values (?1, ?2, 0)")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [limit, name])
    :done = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)
    :ok
  end
end
