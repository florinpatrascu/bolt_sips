defmodule Bolt.Sips.InternalCase do
  use ExUnit.CaseTemplate

  alias Bolt.Sips.Internals.BoltProtocol

  setup do
    uri = neo4j_uri()
    port_opts = [active: false, mode: :binary, packet: :raw]
    {:ok, port} = :gen_tcp.connect(uri.host, uri.port, port_opts)
    :ok = BoltProtocol.handshake(:gen_tcp, port)

    # Neo4j 3.0 does'nt return server info on INIT
    is_bolt_v2 =
      case BoltProtocol.init(:gen_tcp, port, uri.userinfo) do
        {:ok, %{"server" => server}} ->
          is_bolt_v2?(server)

        {:ok, %{}} ->
          false
      end

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, port: port, is_bolt_v2: is_bolt_v2}
  end

  def neo4j_uri do
    "bolt://neo4j:test@localhost:7687"
    |> URI.merge(System.get_env("NEO4J_TEST_URL") || "")
    |> URI.parse()
    |> Map.update!(:host, &String.to_charlist/1)
    |> Map.update!(:userinfo, fn
      nil ->
        {}

      userinfo ->
        userinfo
        |> String.split(":")
        |> List.to_tuple()
    end)
  end

  defp is_bolt_v2?(server) do
    regex = ~r/Neo4j\/(?<major>[\d])\.(?<minor>[\d])\.(?<maintenance>[\d])/
    version_info = Regex.named_captures(regex, server)

    if String.to_integer(version_info["major"]) >= 3 and
         String.to_integer(version_info["minor"]) >= 4 do
      true
    else
      false
    end
  end
end
