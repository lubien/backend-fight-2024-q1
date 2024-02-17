defmodule SqliteServer do
  use GenServer

  # def init_db do
  #   GenServer.call(__MODULE__, :init_db)
  # end

  def insert_customer(name, limit) do
    GenServer.call(__MODULE__, {:insert_customer, {name, limit}})
  end

  def insert_transaction(customer_id, description, type, value) do
    if pid = TenantMapper.get_tenant(customer_id) do
      GenServer.call(pid, {:insert_transaction, {customer_id, description, type, value}})
    else
      :ok
    end
  end

  def get_customer_data(customer_id) do
    if pid = TenantMapper.get_tenant(customer_id) do
      GenServer.call(pid, {:get_customer_data, customer_id})
    else
      :ok
    end
  end

  # Private API
  def start_link(customer_id, name, limit) do
    GenServer.start_link(__MODULE__, [customer_id, name, limit])
    # GenServer.start_link(__MODULE__, [])
  end

  def init([customer_id, name, limit]) do
    path = "#{System.get_env("DATABASE_PATH")}/#{customer_id}.db"
    {:ok, conn} = Exqlite.Sqlite3.open(path)
    do_init_db(conn)
    do_insert_customer(conn, name, limit)
    {:ok, insert_transaction_stmt} = Exqlite.Sqlite3.prepare(conn, """
      insert into transactions (customer_id, description, \"type\", \"value\") values (?1, ?2, ?3, ?4)
    """)
    {:ok, get_customer_data_stmt} = Exqlite.Sqlite3.prepare(conn, """
      select "limit", balance from customers where id = ?1
    """)
    {:ok, %{
      conn: conn,
      insert_transaction_stmt: insert_transaction_stmt,
      get_customer_data_stmt: get_customer_data_stmt
    }}
  end

  def handle_call({:insert_customer, {name, limit}}, _from, %{conn: conn} = state) do
    :ok = do_insert_customer(conn, name, limit)
    {:reply, :ok, state}
  end

  def handle_call({:insert_transaction, {customer_id, description, type, value}}, _from, %{conn: conn, insert_transaction_stmt: statement} = state) do
    # {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "insert into transactions (customer_id, description, \"type\", \"value\") values (?1, ?2, ?3, ?4)")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [customer_id, description, type, value])
    Exqlite.Sqlite3.step(conn, statement)
    # :ok = Exqlite.Sqlite3.release(conn, statement)
    {:reply, :ok, state}
  rescue
    RuntimeError ->
      {:reply, :ok, state}
  end

  def handle_call({:get_customer_data, customer_id}, _from, %{conn: conn, get_customer_data_stmt: statement} = state) do
    :ok = Exqlite.Sqlite3.bind(conn, statement, [customer_id])
    {:row, [limit, balance]} = Exqlite.Sqlite3.step(conn, statement) |> IO.inspect(label: "#{__MODULE__}:#{__ENV__.line} #{DateTime.utc_now}", limit: :infinity)
    {:reply, %{limit: limit, balance: balance}, state}
  rescue
    RuntimeError ->
      {:reply, :ok, state}
  end

  # def handle_call(:init_db, _from, %{conn: conn} = state) do
  #   do_init_db(conn)
  #   {:reply, :ok, state}
  # end

  defp do_init_db(conn) do
    :ok = Exqlite.Sqlite3.execute(conn, "create table customers (id integer primary key, name text, \"limit\" integer, balance integer not null)")
    :ok = Exqlite.Sqlite3.execute(conn, "create table transactions (id integer primary key, description text, customer_id integer, type text, value integer, foreign key (customer_id) references customers(id))")
    # :ok = Exqlite.Sqlite3.execute(conn, "create index transactions_customer_id ON transactions(customer_id)")
    :ok = Exqlite.Sqlite3.execute(conn, """
    CREATE TRIGGER validate_balance_before_insert_transaction
    BEFORE INSERT ON transactions
    BEGIN
      SELECT CASE WHEN (select balance from customers where id = NEW.customer_id) + (
        case when NEW.type = 'c' then +NEW.value else -NEW.value end
      ) < -(select "limit" from customers where id = NEW.customer_id) THEN
        RAISE (ABORT, 'Invalid value')
      END;

      UPDATE customers
      SET balance = customers.balance + (case when NEW.type = 'c' then +NEW.value else -NEW.value end)
      WHERE id = NEW.customer_id;
    END;
    """)
    # customers = [
    #   [1_000 * 100, "Jonathan"],
    #   [800 * 100, "Joseph"],
    #   [10_000 * 100, "Jotaro"],
    #   [100_000 * 100, "Josuke"],
    #   [5_000 * 100, "Giorno"]
    # ]
    # for [limit, name] <- customers do
    #   do_insert_customer(conn, name, limit)
    # end

    :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA synchronous = OFF")
    :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA journal_mode = MEMORY")
    :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA foreign_keys = ON")
  end

  defp do_insert_customer(conn, name, limit) do
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "insert into customers (\"limit\", name, balance) values (?1, ?2, 0)")
    :ok = Exqlite.Sqlite3.bind(conn, statement, [limit, name])
    :done = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)
    :ok
  end
end
