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
end
