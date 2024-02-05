defmodule BackendFight.BankTest do
  use BackendFight.DataCase

  alias BackendFight.Bank

  describe "customers" do
    alias BackendFight.Bank.Customer

    import BackendFight.BankFixtures

    @invalid_attrs %{limit: nil, name: nil}

    test "list_customers/0 returns all customers" do
      customer = customer_fixture()
      assert Bank.list_customers() == [customer]
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      assert Bank.get_customer!(customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{limit: 42, name: "some name"}

      assert {:ok, %Customer{} = customer} = Bank.create_customer(valid_attrs)
      assert customer.limit == 42
      assert customer.name == "some name"
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = customer_fixture()
      update_attrs = %{limit: 43, name: "some updated name"}

      assert {:ok, %Customer{} = customer} = Bank.update_customer(customer, update_attrs)
      assert customer.limit == 43
      assert customer.name == "some updated name"
    end

    test "update_customer/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Bank.update_customer(customer, @invalid_attrs)
      assert customer == Bank.get_customer!(customer.id)
    end

    test "delete_customer/1 deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = Bank.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Bank.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      customer = customer_fixture()
      assert %Ecto.Changeset{} = Bank.change_customer(customer)
    end
  end

  describe "transactions" do
    alias BackendFight.Bank.Transaction

    import BackendFight.BankFixtures

    test "create_transaction/1 with valid data creates a transaction" do
      customer = customer_fixture(%{limit: 1})
      assert Bank.get_customer_balance(customer.id) == 1

      valid_attrs = %{description: "some description", type: "d", value: 1}
      assert {:ok, %Transaction{} = transaction} = Bank.create_transaction(customer, valid_attrs)
      assert transaction.description == "some description"
      assert transaction.type == :d
      assert transaction.value == 1

      assert Bank.get_customer_balance(customer.id) == 0
    end

    test "create_transaction/1 does not work when over limit" do
      customer = customer_fixture(%{limit: 1})
      assert Bank.get_customer_balance(customer.id) == 1
      invalid_attrs = %{description: "some description", type: "d", value: 2}
      assert Bank.get_customer_balance(customer.id) == 1

      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, invalid_attrs)
    end

    test "create_transaction/1 is aware of older transactions" do
      customer = customer_fixture(%{limit: 1000})
      assert Bank.get_customer_balance(customer.id) == 1000
      assert {:ok, %Transaction{} = _transaction} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "d",
        value: 200
      })
      assert Bank.get_customer_balance(customer.id) == 800
      assert {:ok, %Transaction{} = _transaction} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "c",
        value: 100
      })
      assert Bank.get_customer_balance(customer.id) == 900
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "d",
        value: 901
      })
      assert Bank.get_customer_balance(customer.id) == 900
      assert {:ok, %Transaction{} = _transaction} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "d",
        value: 700
      })
      assert Bank.get_customer_balance(customer.id) == 200
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "d",
        value: 700
      })
      assert Bank.get_customer_balance(customer.id) == 200
      assert {:ok, %Transaction{} = _transaction} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "c",
        value: 800
      })
      assert Bank.get_customer_balance(customer.id) == 1000
      assert {:error, %Ecto.Changeset{}} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "d",
        value: 1001
      })
      assert Bank.get_customer_balance(customer.id) == 1000
      assert {:ok, %Transaction{} = _transaction} = Bank.create_transaction(customer, %{
        description: "some description",
        type: "d",
        value: 1000
      })
      assert Bank.get_customer_balance(customer.id) == 0
    end
  end
end
