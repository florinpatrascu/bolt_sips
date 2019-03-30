defmodule Bolt.Sips.InternalCase do
  use ExUnit.CaseTemplate

  alias Bolt.Sips.Internals.BoltProtocol

  setup do
    uri = neo4j_uri()
    port_opts = [active: false, mode: :binary, packet: :raw]
    {:ok, port} = :gen_tcp.connect(uri.host, uri.port, port_opts)
    {:ok, bolt_version} = BoltProtocol.handshake(:gen_tcp, port)
    {:ok, _} = init(:gen_tcp, port, bolt_version, uri.userinfo)

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, port: port, is_bolt_v2: bolt_version >= 2, bolt_version: bolt_version}
  end

  defp neo4j_uri do
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

  defp init(transport, port, 3, auth) do
    BoltProtocol.hello(transport, port, 3, auth)
  end

  defp init(transport, port, bolt_version, auth) do
    BoltProtocol.init(transport, port, bolt_version, auth)
  end
end
