defmodule Bolt.Sips.Internals.BoltProtocolV1Test do
  use Bolt.Sips.InternalCase
  @moduletag :bolt_v1
  alias Bolt.Sips.Internals.BoltProtocol

  test "allows to recover from error with ack_failure", %{port: port, bolt_version: bolt_version} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "What?")

    assert :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert [{:success, _} | _] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")
  end

  test "returns proper error when misusing ack_failure and reset", %{
    port: port,
    bolt_version: bolt_version
  } do
    assert %Bolt.Sips.Internals.Error{} = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)
  end

  test "works within a transaction", %{port: port, bolt_version: bolt_version} do
    assert [{:success, _}, {:success, _}] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "BEGIN")

    assert [{:success, _} | _] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")

    assert [{:success, _}, {:success, _}] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "COMMIT")
  end

  test "works with rolled-back transactions", %{port: port, bolt_version: bolt_version} do
    assert [{:success, _}, {:success, _}] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "BEGIN")

    assert [{:success, _} | _] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")

    assert [{:success, _}, {:success, _}] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "ROLLBACK")
  end
end
