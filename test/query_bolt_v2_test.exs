defmodule Bolt.Sips.QueryBoltV2Test do
  use Bolt.Sips.ConnCase, async: true
  @moduletag :bolt_v2

  alias Bolt.Sips.Types.{Duration, DateTimeWithTZOffset, Point, TimeWithTZOffset}
  alias Bolt.Sips.{TypesHelper, Response}

  setup_all do
    # reuse the same connection for all the tests in the suite
    conn = Bolt.Sips.conn()
    {:ok, [conn: conn]}
  end

  test "transform Point in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN point($point_data) AS pt"
    params = %{point_data: Point.create(:cartesian, 50, 60.5)}

    assert {:ok, %Response{results: res}} = Bolt.Sips.query(conn, query, params)

    assert res == [
             %{
               "pt" => %Bolt.Sips.Types.Point{
                 crs: "cartesian",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 7203,
                 x: 50.0,
                 y: 60.5,
                 z: nil
               }
             }
           ]
  end

  test "transform Duration in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN duration($d) AS d"

    params = %{
      d: %Duration{
        days: 0,
        hours: 0,
        minutes: 54,
        months: 12,
        nanoseconds: 0,
        seconds: 65,
        weeks: 0,
        years: 1
      }
    }

    expected = %Duration{
      days: 0,
      hours: 0,
      minutes: 55,
      months: 0,
      nanoseconds: 0,
      seconds: 5,
      weeks: 0,
      years: 2
    }

    assert {:ok, %Response{results: [%{"d" => ^expected}]}} = Bolt.Sips.query(conn, query, params)
  end

  test "transform Date in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN date($d) AS d"
    params = %{d: ~D[2019-02-04]}

    assert {:ok, %Response{results: res}} = Bolt.Sips.query(conn, query, params)
    assert res == [%{"d" => ~D[2019-02-04]}]
  end

  test "transform TimeWithTZOffset in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN time($t) AS t"
    time_with_tz = %TimeWithTZOffset{time: ~T[12:45:30.250876], timezone_offset: 3600}
    params = %{t: time_with_tz}

    assert {:ok, %Response{results: [%{"t" => ^time_with_tz}]}} =
             Bolt.Sips.query(conn, query, params)
  end

  test "transform DateTimeWithTZOffset in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN datetime($t) AS t"

    date_time_with_tz = %DateTimeWithTZOffset{
      naive_datetime: ~N[2016-05-24 13:26:08.543267],
      timezone_offset: 7200
    }

    params = %{t: date_time_with_tz}

    assert {:ok, %Response{results: [%{"t" => ^date_time_with_tz}]}} =
             Bolt.Sips.query(conn, query, params)
  end

  test "transform DateTime With TimeZone id (UTC) in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN datetime($t) AS t"

    date_time_with_tz_id =
      TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543218], "Etc/UTC")

    params = %{t: date_time_with_tz_id}

    assert {:ok, %Response{results: [%{"t" => ^date_time_with_tz_id}]}} =
             Bolt.Sips.query(conn, query, params)
  end

  test "transform DateTime With TimeZone id (Non-UTC) in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN datetime($t) AS t"

    date_time_with_tz_id =
      TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543789], "Europe/Paris")

    params = %{t: date_time_with_tz_id}

    assert {:ok, %Response{results: [%{"t" => ^date_time_with_tz_id}]}} =
             Bolt.Sips.query(conn, query, params)
  end

  test "transform NaiveDateTime in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN localdatetime($t) AS t"

    ndt = ~N[2016-05-24 13:26:08.543156]
    params = %{t: ndt}

    assert {:ok, %Response{results: [%{"t" => ^ndt}]}} = Bolt.Sips.query(conn, query, params)
  end

  test "transform Time in cypher-compliant data", context do
    conn = context[:conn]
    query = "RETURN localtime($t) AS t"

    t = ~T[13:26:08.543440]
    params = %{t: t}

    assert {:ok, %Response{results: [%{"t" => ^t}]}} = Bolt.Sips.query(conn, query, params)
  end
end
