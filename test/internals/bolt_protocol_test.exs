defmodule Bolt.Sips.Internals.BoltProtocolTest do
  use Bolt.Sips.InternalCase
  alias Bolt.Sips.Internals.BoltProtocol

  test "works for small queries", %{port: port} do
    string = Enum.to_list(0..100) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] = BoltProtocol.run_statement(:gen_tcp, port, query, params)

    assert [record: [^string], success: _] = records
  end

  test "works for big queries", %{port: port} do
    string = Enum.to_list(0..25_000) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] = BoltProtocol.run_statement(:gen_tcp, port, query, params)

    assert [record: [^string], success: _] = records
  end

  test "returns errors for wrong cypher queris", %{port: port} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "What?")
  end

  test "allows to recover from error with ack_failure", %{port: port} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "What?")

    assert :ok = BoltProtocol.ack_failure(:gen_tcp, port)
    assert [{:success, _} | _] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN 1 as num")
  end

  test "allows to recover from error with reset", %{port: port} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "What?")

    assert :ok = BoltProtocol.reset(:gen_tcp, port)
    assert [{:success, _} | _] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN 1 as num")
  end

  test "returns proper error when using a bad session", %{port: port} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "What?")

    error = BoltProtocol.run_statement(:gen_tcp, port, "RETURN 1 as num")

    assert %Bolt.Sips.Internals.Error{} = error
    assert error.message =~ ~r/The session is in a failed state/
  end

  test "returns proper error when misusing ack_failure and reset", %{port: port} do
    assert %Bolt.Sips.Internals.Error{} = BoltProtocol.ack_failure(:gen_tcp, port)
    :gen_tcp.close(port)
    assert %Bolt.Sips.Internals.Error{} = BoltProtocol.reset(:gen_tcp, port)
  end

  test "returns proper error when using a closed port", %{port: port} do
    :gen_tcp.close(port)

    assert %Bolt.Sips.Internals.Error{type: :connection_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "RETURN 1 as num")
  end

  test "works within a transaction", %{port: port} do
    assert [{:success, _}, {:success, _}] = BoltProtocol.run_statement(:gen_tcp, port, "BEGIN")
    assert [{:success, _} | _] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN 1 as num")
    assert [{:success, _}, {:success, _}] = BoltProtocol.run_statement(:gen_tcp, port, "COMMIT")
  end

  test "works with rolled-back transactions", %{port: port} do
    assert [{:success, _}, {:success, _}] = BoltProtocol.run_statement(:gen_tcp, port, "BEGIN")
    assert [{:success, _} | _] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN 1 as num")
    assert [{:success, _}, {:success, _}] = BoltProtocol.run_statement(:gen_tcp, port, "ROLLBACK")
  end

  test "an invalid parameter value yields an error", %{port: port} do
    cypher = "MATCH (n:Person {invalid: {an_elixir_datetime}}) RETURN TRUE"

    assert_raise Bolt.Sips.Internals.PackStream.EncodeError, ~r/^unable to encode value: /i, fn ->
      BoltProtocol.run_statement(:gen_tcp, port, cypher, %{an_elixir_datetime: DateTime.utc_now()})
    end
  end

  test "Temporal / patial types does not work prior to Neo4j 3.4", %{
    port: port,
    is_bolt_v2: is_bolt_v2
  } do
    test_bolt_v2(port, is_bolt_v2)
  end

  @doc """
  Test valid returns for Bolt V1.
  """
  def test_bolt_v2(port, false) do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "RETURN date('2018-01-01') as d")

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "RETURN time('12:45:30.25+01:00') AS t")

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "RETURN local_time('12:45:30.25') AS t")

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN duration('P1Y3M34DT54.00000555S') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN localdatetime('2018-04-05T12:34:00.543') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN datetime('2018-04-05T12:34:23.543+01:00') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN datetime('2018-04-05T12:34:23.543[Europe/Berlin]') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, "RETURN point({x: 40, y: 45}) AS p")

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN point({longitude: 40, latitude: 45}) AS p"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN point({x: 40, y: 45, z: 150}) AS p"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN point({longitude: 40, latitude: 45, height: 150}) AS p"
             )
  end

  @doc """
  Test valid returns for Bolt V2.
  """
  def test_bolt_v2(port, true) do
    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [[sig: 68, fields: [17167]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN date('2017-01-01') as d")

    assert [
             success: %{"fields" => ["t"], "result_available_after" => _},
             record: [[sig: 84, fields: [45_930_250_000_000, 3600]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN time('12:45:30.25+01:00') AS t")

    assert [
             success: %{"fields" => ["t"], "result_available_after" => _},
             record: [[sig: 116, fields: [45_930_250_000_000]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN localtime('12:45:30.25') AS t")

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [[sig: 69, fields: [15, 34, 54, 5550]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN duration('P1Y3M34DT54.00000555S') AS d"
             )

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [[sig: 100, fields: [1_522_931_640, 543_000_000]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN localdatetime('2018-04-05T12:34:00.543') AS d"
             )

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [[sig: 70, fields: [1_522_931_663, 543_000_000, 3600]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN datetime('2018-04-05T12:34:23.543+01:00') AS d"
             )

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [[sig: 102, fields: [1_522_931_663, 543_000_000, "Europe/Berlin"]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN datetime('2018-04-05T12:34:23.543[Europe/Berlin]') AS d"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [[sig: 88, fields: [7203, 40.0, 45.0]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = BoltProtocol.run_statement(:gen_tcp, port, "RETURN point({x: 40, y: 45}) AS p")

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [[sig: 88, fields: [4326, 40.0, 45.0]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN point({longitude: 40, latitude: 45}) AS p"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [[sig: 89, fields: [9157, 40.0, 45.0, 150.0]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN point({x: 40, y: 45, z: 150}) AS p"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [[sig: 89, fields: [4979, 40.0, 45.0, 150.0]]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               "RETURN point({longitude: 40, latitude: 45, height: 150}) AS p"
             )
  end
end
