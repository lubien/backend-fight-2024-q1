defmodule BackendFight.DNSClusterResolver do
  @moduledoc false

  require Record

  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  def basename(node_name) when is_atom(node_name) do
    [basename, _] = String.split(to_string(node_name), "@")
    basename
  end

  def connect_node(node_name) when is_atom(node_name), do: Node.connect(node_name)

  def list_nodes, do: Node.list(:visible)

  def lookup(query, type) when is_binary(query) and type in [:a, :aaaa] do
    query
    |> String.split()
    |> Enum.reduce([], fn query, acc ->
      case :inet.getaddr(~c"#{query}", :inet) do
        {:ok, addr} -> [addr] ++ acc
        {:error, _} -> acc
      end
    end)
  end
end
