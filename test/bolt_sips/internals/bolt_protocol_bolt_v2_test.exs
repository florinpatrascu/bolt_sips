defmodule Bolt.Sips.Internals.BoltProtoolBoltV2Test do
  use Bolt.Sips.InternalCase
  @moduletag :bolt_v2

  alias Bolt.Sips.Internals.BoltProtocol

  describe "Temporal types" do
    test "Local date", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["d"]},
               record: [~D[2017-01-01]],
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN date('2017-01-01') as d"
               )
    end

    test "Time with Timezone Offset", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["t"]},
               record: [
                 %Bolt.Sips.Types.TimeWithTZOffset{
                   time: ~T[12:45:30.250000],
                   timezone_offset: 3600
                 }
               ],
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN time('12:45:30.25+01:00') AS t"
               )
    end

    test "Local time", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["t"]},
               record: [~T[12:45:30.250000]],
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN localtime('12:45:30.25') AS t"
               )
    end

    test "Duration", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["d"]},
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
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN duration('P1Y3M34DT54.00000555S') AS d"
               )
    end

    test "Local datetime", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["d"]},
               record: [~N[2018-04-05 12:34:00.654321]],
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN localdatetime('2018-04-05T12:34:00.654321') AS d"
               )
    end

    test "datetime with timezone offset", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["d"]},
               record: [
                 %Bolt.Sips.Types.DateTimeWithTZOffset{
                   naive_datetime: ~N[2018-04-05 12:34:23.654321],
                   timezone_offset: 3600
                 }
               ],
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN datetime('2018-04-05T12:34:23.654321+01:00') AS d"
               )
    end

    test "datetime with timezone id", %{port: port, bolt_version: bolt_version} do
      dt =
        Bolt.Sips.TypesHelper.datetime_with_micro(~N[2018-04-05T12:34:23.654321], "Europe/Berlin")

      assert [
               success: %{"fields" => ["d"]},
               record: [^dt],
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN datetime('2018-04-05T12:34:23.654321[Europe/Berlin]') AS d"
               )
    end
  end

  describe "Spatial types" do
    test "Point 2D cartesian", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["p"]},
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
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN point({x: 40, y: 45}) AS p"
               )
    end

    test "Point2D geographic", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["p"]},
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
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN point({longitude: 40, latitude: 45}) AS p"
               )
    end

    test "Point 3D cartesian", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["p"]},
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
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN point({x: 40, y: 45, z: 150}) AS p"
               )
    end

    test "Point 3D geographic", %{port: port, bolt_version: bolt_version} do
      assert [
               success: %{"fields" => ["p"]},
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
               success: %{"type" => "r"}
             ] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN point({longitude: 40, latitude: 45, height: 150}) AS p"
               )
    end
  end
end
