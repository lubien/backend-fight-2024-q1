defmodule BackendFight.BankTest do
  use BackendFight.DataCase

  alias BackendFight.Bank

  describe "customers" do
    alias BackendFight.Bank.Customer

    import BackendFight.BankFixtures

    @invalid_attrs %{limit: nil, name: nil}

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{limit: 42, name: "some name"}

      assert {:ok, %Customer{} = customer} = Bank.create_customer(valid_attrs)
      assert customer.limit == 42
      assert customer.name == "some name"
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_customer(@invalid_attrs)
    end
  end

  describe "transactions" do
    alias BackendFight.Bank.Transaction

    import BackendFight.BankFixtures

    test "create_transaction/1 with valid data creates a transaction" do
      customer = customer_fixture(%{limit: 1})
      assert Bank.get_customer_balance(customer.id) == 0

      assert {:ok, %Transaction{} = transaction, _new_balance} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 1
      })
      assert transaction.description == "trade"
      assert transaction.type == :d
      assert transaction.value == 1

      assert Bank.get_customer_balance(customer.id) == -1
    end

    test "create_transaction/1 does not work with non integers" do
      customer = customer_fixture(%{limit: 1})
      assert Bank.get_customer_balance(customer.id) == 0
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 0.5
      })
      assert Bank.get_customer_balance(customer.id) == 0
    end

    test "create_transaction/1 does not work with names not in the range on 1..10 chars" do
      customer = customer_fixture(%{limit: 1})
      assert Bank.get_customer_balance(customer.id) == 0
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: nil,
        type: "d",
        value: 1
      })
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "12345678901 more",
        type: "d",
        value: 1
      })
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "",
        type: "d",
        value: 1
      })
      assert Bank.get_customer_balance(customer.id) == 0
    end

    test "create_transaction/1 does not work when over limit" do
      customer = customer_fixture(%{limit: 1})
      assert Bank.get_customer_balance(customer.id) == 0
      invalid_attrs = %{description: "trade", type: "d", value: 2}
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, invalid_attrs)
      assert Bank.get_customer_balance(customer.id) == 0
    end

    test "create_transaction/1 is aware of older transactions" do
      customer = customer_fixture(%{limit: 1000})
      assert Bank.get_customer_balance(customer.id) == 0
      assert {:ok, %Transaction{} = _transaction, _new_balance} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 200
      })
      assert Bank.get_customer_balance(customer.id) == -200
      assert {:ok, %Transaction{} = _transaction, _new_balance} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "c",
        value: 100
      })
      assert Bank.get_customer_balance(customer.id) == -100
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 901
      })
      assert Bank.get_customer_balance(customer.id) == -100
      assert {:ok, %Transaction{} = _transaction, _new_balance} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 700
      })
      assert Bank.get_customer_balance(customer.id) == -800
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 700
      })
      assert Bank.get_customer_balance(customer.id) == -800
      assert {:ok, %Transaction{} = _transaction, _new_balance} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "c",
        value: 800
      })
      assert Bank.get_customer_balance(customer.id) == 0
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 1001
      })
      assert Bank.get_customer_balance(customer.id) == 0
      assert {:ok, %Transaction{} = _transaction, _new_balance} = Bank.create_transaction(customer, %{
        description: "trade",
        type: "d",
        value: 1000
      })
      assert Bank.get_customer_balance(customer.id) == -1000
    end
  end
end
