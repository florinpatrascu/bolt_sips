defmodule Bolt.Sips.Internals.BoltProtocolTest do
  use Bolt.Sips.InternalCase
  alias Bolt.Sips.Internals.BoltProtocol

  test "works for small queries", %{port: port, bolt_version: bolt_version} do
    string = Enum.to_list(0..100) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] =
      BoltProtocol.run_statement(:gen_tcp, port, bolt_version, query, params)

    assert [record: [^string], success: _] = records
  end

  test "works for big queries", %{port: port, bolt_version: bolt_version} do
    string = Enum.to_list(0..25_000) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] =
      BoltProtocol.run_statement(:gen_tcp, port, bolt_version, query, params)

    assert [record: [^string], success: _] = records
  end

  test "returns errors for wrong cypher queris", %{port: port, bolt_version: bolt_version} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "What?")
  end

  test "allows to recover from error with ack_failure", %{port: port, bolt_version: bolt_version} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "What?")

    assert :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert [{:success, _} | _] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")
  end

  test "allows to recover from error with reset", %{port: port, bolt_version: bolt_version} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "What?")

    assert :ok = BoltProtocol.reset(:gen_tcp, port, bolt_version)

    assert [{:success, _} | _] =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")
  end

  test "returns proper error when using a bad session", %{port: port, bolt_version: bolt_version} do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "What?")

    error = BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")

    assert %Bolt.Sips.Internals.Error{} = error
    assert error.message =~ ~r/The session is in a failed state/
  end

  test "returns proper error when misusing ack_failure and reset", %{
    port: port,
    bolt_version: bolt_version
  } do
    assert %Bolt.Sips.Internals.Error{} = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)
    :gen_tcp.close(port)
    assert %Bolt.Sips.Internals.Error{} = BoltProtocol.reset(:gen_tcp, port, bolt_version)
  end

  test "returns proper error when using a closed port", %{port: port, bolt_version: bolt_version} do
    :gen_tcp.close(port)

    assert %Bolt.Sips.Internals.Error{type: :connection_error} =
             BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 as num")
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

  test "an invalid parameter value yields an error", %{port: port, bolt_version: bolt_version} do
    cypher = "MATCH (n:Person {invalid: {a_tuple}}) RETURN TRUE"

    assert_raise Bolt.Sips.Internals.PackStreamError, ~r/^unable to encode/i, fn ->
      BoltProtocol.run_statement(:gen_tcp, port, bolt_version, cypher, %{
        a_tuple: {:error, "don't work"}
      })
    end
  end

  test "Temporal / patial types does not work prior to bolt V2", %{
    port: port,
    bolt_version: bolt_version
  } do
    test_bolt_v2(port, bolt_version)
  end

  @doc """
  Test valid returns for Bolt V1.
  """
  def test_bolt_v2(port, bolt_version) when bolt_version == 1 do
    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN date('2018-01-01') as d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN time('12:45:30.25+01:00') AS t"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN local_time('12:45:30.25') AS t"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN duration('P1Y3M34DT54.00000555S') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN localdatetime('2018-04-05T12:34:00.543') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN datetime('2018-04-05T12:34:23.543+01:00') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN datetime('2018-04-05T12:34:23.543[Europe/Berlin]') AS d"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({x: 40, y: 45}) AS p"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({longitude: 40, latitude: 45}) AS p"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({x: 40, y: 45, z: 150}) AS p"
             )

    :ok = BoltProtocol.ack_failure(:gen_tcp, port, bolt_version)

    assert %Bolt.Sips.Internals.Error{type: :cypher_error} =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({longitude: 40, latitude: 45, height: 150}) AS p"
             )
  end

  @doc """
  Test valid returns for Bolt V2.
  """
  def test_bolt_v2(port, bolt_version) when bolt_version >= 2 do
    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [~D[2017-01-01]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN date('2017-01-01') as d"
             )

    assert [
             success: %{"fields" => ["t"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.TimeWithTZOffset{
                 time: ~T[12:45:30.250000],
                 timezone_offset: 3600
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN time('12:45:30.25+01:00') AS t"
             )

    assert [
             success: %{"fields" => ["t"], "result_available_after" => _},
             record: [~T[12:45:30.250000]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN localtime('12:45:30.25') AS t"
             )

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.Duration{
                 days: 34,
                 hours: 0,
                 minutes: 0,
                 months: 3,
                 nanoseconds: 5550,
                 seconds: 54,
                 weeks: 0,
                 years: 1
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN duration('P1Y3M34DT54.00000555S') AS d"
             )

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [~N[2018-04-05 12:34:00.543]],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN localdatetime('2018-04-05T12:34:00.543') AS d"
             )

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.DateTimeWithTZOffset{
                 naive_datetime: ~N[2018-04-05 12:34:23.543],
                 timezone_offset: 3600
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN datetime('2018-04-05T12:34:23.543+01:00') AS d"
             )

    dt = Bolt.Sips.TypesHelper.datetime_with_micro(~N[2018-04-05T12:34:23.543], "Europe/Berlin")

    assert [
             success: %{"fields" => ["d"], "result_available_after" => _},
             record: [^dt],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN datetime('2018-04-05T12:34:23.543[Europe/Berlin]') AS d"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.Point{
                 crs: "cartesian",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 7203,
                 x: 40.0,
                 y: 45.0,
                 z: nil
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({x: 40, y: 45}) AS p"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.Point{
                 crs: "wgs-84",
                 height: nil,
                 latitude: 45.0,
                 longitude: 40.0,
                 srid: 4326,
                 x: 40.0,
                 y: 45.0,
                 z: nil
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({longitude: 40, latitude: 45}) AS p"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.Point{
                 crs: "cartesian-3d",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 9157,
                 x: 40.0,
                 y: 45.0,
                 z: 150.0
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({x: 40, y: 45, z: 150}) AS p"
             )

    assert [
             success: %{"fields" => ["p"], "result_available_after" => _},
             record: [
               %Bolt.Sips.Types.Point{
                 crs: "wgs-84-3d",
                 height: 150.0,
                 latitude: 45.0,
                 longitude: 40.0,
                 srid: 4979,
                 x: 40.0,
                 y: 45.0,
                 z: 150.0
               }
             ],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] =
             BoltProtocol.run_statement(
               :gen_tcp,
               port,
               bolt_version,
               "RETURN point({longitude: 40, latitude: 45, height: 150}) AS p"
             )
  end
end
