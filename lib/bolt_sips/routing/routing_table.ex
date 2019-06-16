defmodule Bolt.Sips.Routing.RoutingTable do
  @moduledoc ~S"""
  representing the routing table elements

  There are a couple of ways to get the routing table from the server, for recent Neo4j servers, and with the
  latest version of Bolt.Sips, you could use this query:

      Bolt.Sips.query!(Bolt.Sips.conn, "call dbms.cluster.routing.getRoutingTable({props})", %{props: %{}})

      [
        %{
          "servers" => [
            %{"addresses" => ["localhost:7687"], "role" => "WRITE"},
            %{"addresses" => ["localhost:7689", "localhost:7688"], "role" => "READ"},
            %{
              "addresses" => ["localhost:7688", "localhost:7689", "localhost:7687"],
              "role" => "ROUTE"
            }
          ],
          "ttl" => 300
        }
      ]

  """

  @type t :: %__MODULE__{
          roles: %{(:read | :write | :route | :direct) => %{String.t() => non_neg_integer}},
          updated_at: non_neg_integer,
          ttl: non_neg_integer
        }
  defstruct roles: %{}, ttl: 300, updated_at: 0

  alias Bolt.Sips.Utils

  @write "WRITE"
  @read "READ"
  @route "ROUTE"

  @spec parse(map) :: __MODULE__.t() | {:error, String.t()}
  def parse(%{"servers" => servers, "ttl" => ttl}) do
    with {:ok, roles} <- parse_servers(servers),
         {:ok, ttl} <- parse_ttl(ttl) do
      %__MODULE__{roles: roles, ttl: ttl, updated_at: Utils.now()}
    end
  end

  def parse(map),
    do: {:error, "not a valid routing table: " <> inspect(map)}

  @spec parse_servers(list()) :: {:ok, map()}
  defp parse_servers(servers) do
    parsed_servers =
      servers
      |> Enum.reduce(%{}, fn %{"addresses" => addresses, "role" => role}, acc ->
        with {:ok, atomized_role} <- to_atomic_role(role) do
          roles =
            addresses
            |> Enum.reduce(acc, fn address, acc ->
              Map.update(acc, atomized_role, %{address => 0}, &Map.put(&1, address, 0))
            end)

          roles
        else
          _ -> acc
        end
      end)

    {:ok, parsed_servers}
  end

  defp to_atomic_role(role) when role in [@read, @write, @route] do
    atomic_role =
      case role do
        @read -> :read
        @write -> :write
        @route -> :route
        _ -> :direct
      end

    {:ok, atomic_role}
  end

  defp to_atomic_role(_), do: {:error, :alien_role}

  def parse_ttl(ttl), do: {:ok, ensure_integer(ttl)}

  @doc false
  def ttl_expired?(updated_at, ttl) do
    updated_at + ttl <= Utils.now()
  end

  defp ensure_integer(ttl) when is_nil(ttl), do: 0
  defp ensure_integer(ttl) when is_binary(ttl), do: String.to_integer(ttl)
  defp ensure_integer(ttl) when is_integer(ttl), do: ttl
  defp ensure_integer(ttl), do: raise(ArgumentError, "invalid ttl: " <> inspect(ttl))
end
