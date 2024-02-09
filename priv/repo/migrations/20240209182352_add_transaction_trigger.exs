defmodule BackendFight.Repo.Migrations.AddTransactionTrigger do
  use Ecto.Migration

  alias BackendFight.Repo

  def up do
    BackendFight.Repo.query("""
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
  end

  def down do
    Repo.query("""
    DROP TRIGGER validate_balance_before_insert_transaction;
    """)
  end
end
