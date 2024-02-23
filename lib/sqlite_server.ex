defmodule SqliteServer do
  use GenServer
  require Logger

  def insert_transaction(id, description, type, value) do
    if pid = pid(id) do
      GenServer.call(pid, {:insert_transaction, {description, type, value}})
    else
      {:error, :not_found}
    end
  end

  def get_customer_data(id) do
    if pid = pid(id) do
      GenServer.call(pid, :get_customer_data)
    else
      {:error, :not_found}
    end
  end

  # Private API
  def start_link([customer_id, name, limit]) do
    GenServer.start_link(__MODULE__, [customer_id, name, limit], name: name(customer_id))
  end

  def init([customer_id, name, limit]) do
    path = "#{System.get_env("DATABASE_PATH")}/#{customer_id}.db"
    {:ok, conn} = Exqlite.Sqlite3.open(path)
    do_init_db(conn)
    do_insert_customer(conn, name, limit)

    {:ok, insert_transaction_stmt} =
      Exqlite.Sqlite3.prepare(conn, """
        insert into transactions (description, \"type\", \"value\") values (?1, ?2, ?3)
      """)

    {:ok, get_customer_stmt} =
      Exqlite.Sqlite3.prepare(conn, """
      select "limit", balance from customers limit 1
      """)

    {:ok, get_customer_data_stmt} =
      Exqlite.Sqlite3.prepare(conn, """
        select
          "limit" as "valor",
          balance as "descricao",
          'user' as "tipo",
          'now' as "realizada_em"
        from customers

        UNION ALL

        select * from (
          select
            "value" as "valor",
            description as "descricao",
            "type" as "tipo",
            inserted_at as "realizada_em"
          from
            transactions
          ORDER BY
            inserted_at desc
          LIMIT 10
        ) as s1
      """)

    Logger.info("Tenant #{customer_id} started")

    {:ok,
     %{
       conn: conn,
       insert_transaction_stmt: insert_transaction_stmt,
       get_customer_stmt: get_customer_stmt,
       get_customer_data_stmt: get_customer_data_stmt
     }}
  end

  def handle_call(
        {:insert_transaction, {description, type, value}},
        _from,
        %{
          conn: conn,
          insert_transaction_stmt: insert_transaction_stmt,
          get_customer_stmt: get_customer_stmt
        } = state
      ) do
    :ok = execute(conn, insert_transaction_stmt, [description, type, value])
    {:reply, one(conn, get_customer_stmt, []), state}
  end

  def handle_call(:get_customer_data, _from, %{conn: conn, get_customer_data_stmt: statement} = state) do
    {:reply, all(conn, statement, []), state}
  end

  defp do_init_db(conn) do
    :ok =
      execute(conn, """
        create table if not exists customers (id integer primary key, name text, \"limit\" integer, balance integer not null)
      """)

    :ok =
      execute(conn, """
      create table if not exists transactions (
        id integer primary key,
        description text,
        customer_id integer,
        type text,
        value integer,
        inserted_at integer default (CAST(ROUND((julianday('now') - 2440587.5)*86400000) As INTEGER)),
        foreign key (customer_id) references customers(id))
      """)

    :ok =
      execute(
        conn,
        "create index if not exists transactions_inserted_at_desc ON transactions(inserted_at desc)"
      )

    :ok =
      execute(conn, """
      CREATE TRIGGER if not exists validate_balance_before_insert_transaction
      BEFORE INSERT ON transactions
      BEGIN
        SELECT CASE WHEN (c.balance + (CASE WHEN NEW.type = 'c' THEN NEW.value ELSE -NEW.value END)) < -c."limit"
          THEN RAISE (ABORT, 'Invalid value')
        END
        FROM (SELECT balance, "limit" FROM customers) AS c;

        UPDATE customers
        SET balance = customers.balance + (case when NEW.type = 'c' then +NEW.value else -NEW.value end);
      END;
      """)

    :ok = execute(conn, "PRAGMA synchronous = OFF")
    :ok = execute(conn, "PRAGMA journal_mode = WAL")
    :ok = execute(conn, "PRAGMA threads = 32")
    :ok = execute(conn, "PRAGMA temp_store = MEMORY")
    :ok = execute(conn, "pragma mmap_size = 30000000000")
    :ok = execute(conn, "pragma page_size = 32768")
  end

  defp do_insert_customer(conn, name, limit) do
    {:ok, statement} =
      Exqlite.Sqlite3.prepare(
        conn,
        "insert into customers (\"limit\", name, balance) values (?1, ?2, 0)"
      )

    :ok = execute(conn, statement, [limit, name])
    :ok = Exqlite.Sqlite3.release(conn, statement)
    :ok
  end

  defp execute(conn, stmt) do
    Exqlite.Sqlite3.execute(conn, stmt)
  end

  defp execute(conn, stmt, bindings) do
    :ok = Exqlite.Sqlite3.bind(conn, stmt, bindings)
    Exqlite.Sqlite3.step(conn, stmt)
    :ok
  end

  defp one(conn, stmt, bindings) do
    :ok = Exqlite.Sqlite3.bind(conn, stmt, bindings)
    {:row, row} = Exqlite.Sqlite3.step(conn, stmt)
    {:ok, row}
  end

  defp all(conn, stmt, bindings) do
    :ok = Exqlite.Sqlite3.bind(conn, stmt, bindings)

    Stream.unfold(:ok, fn _ ->
      case Exqlite.Sqlite3.step(conn, stmt) do
        {:row, row} ->
          {row, :ok}

        :done ->
          nil
      end
    end)
    |> Enum.to_list()
  end

  defp name(customer_id) do
    String.to_atom("sqlite_server_customer_#{customer_id}")
  end

  defp pid(customer_id) do
    name(customer_id)
    |> Process.whereis()
  end
end
