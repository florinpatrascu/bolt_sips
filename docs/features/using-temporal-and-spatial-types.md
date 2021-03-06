# Using temporal and spatial types

Temporal and spatial types are supported since Neo4J 3.4.
You can used the elixir structs: Time, NaiveDateTime, DateTime,
as well as the Bolt Sips structs: DateTimeWithTZOffset, TimeWithTZOffset, Duration, Point.

```elixir
$ MIX_ENV=test iex -S mix
Erlang/OTP 21 [erts-10.0.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe]

Interactive Elixir (1.7.3) - press Ctrl+C to exit (type h() ENTER for help)
iex> alias Bolt.Sips.Types.{Duration, DateTimeWithTZOffset, Point, TimeWithTZOffset}
[Bolt.Sips.Types.Duration, Bolt.Sips.Types.DateTimeWithTZOffset,
 Bolt.Sips.Types.Point, Bolt.Sips.Types.TimeWithTZOffset]

iex> alias Bolt.Sips.TypesHelper
Bolt.Sips.TypesHelper

iex> {:ok, pid} = Bolt.Sips.start_link(url: "localhost", basic_auth: [username: "neo4j", password: "test"])
{:ok, #PID<0.236.0>}

iex> conn = Bolt.Sips.conn
:bolt_sips_pool

# Date without timezone with Date
iex(8)> Bolt.Sips.query!(conn, "RETURN date($d) AS d", %{d: ~D[2019-02-04]})
[%{"d" => ~D[2019-02-04]}]

# Time without timezone with Time
iex> Bolt.Sips.query!(conn, "RETURN localtime($t) AS t", %{t: ~T[13:26:08.543440]})
[%{"t" => ~T[13:26:08.543440]}]

# Datetime without timezone with Naive DateTime
iex> Bolt.Sips.query!(conn, "RETURN localdatetime($ldt) AS ldt", %{ldt: ~N[2016-05-24 13:26:08.543]})
[%{"ldt" => ~N[2016-05-24 13:26:08.543]}]

# Datetime with timezone ID with DateTime (through Calendar)
iex> date_time_with_tz_id = TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Paris")
#DateTime<2016-05-24 13:26:08.543+02:00 CEST Europe/Paris>
iex> Bolt.Sips.query!(conn, "RETURN datetime($dt) AS dt", %{dt: date_time_with_tz_id})
[%{"dt" => #DateTime<2016-05-24 13:26:08.543+02:00 CEST Europe/Paris>}]

# Datetime with timezone offset (seconds) with DateTimeWithTZOffset
iex(17)> date_time_with_tz = DateTimeWithTZOffset.create(~N[2016-05-24 13:26:08.543], 7200)
%Bolt.Sips.Types.DateTimeWithTZOffset{
  naive_datetime: ~N[2016-05-24 13:26:08.543],
  timezone_offset: 7200
}
iex(18)> Bolt.Sips.query!(conn, "RETURN datetime($dt) AS dt", %{dt: date_time_with_tz})
[
  %{
    "dt" => %Bolt.Sips.Types.DateTimeWithTZOffset{
      naive_datetime: ~N[2016-05-24 13:26:08.543],
      timezone_offset: 7200
    }
  }
]


# Datetime with timezone offset (seconds) with TimeWithTZOffset
iex> time_with_tz = TimeWithTZOffset.create(~T[12:45:30.250000], 3600)
%Bolt.Sips.Types.TimeWithTZOffset{
  time: ~T[12:45:30.250000],
  timezone_offset: 3600
}
iex> Bolt.Sips.query!(conn, "RETURN time($t) AS t", %{t: time_with_tz})
[
  %{
    "t" => %Bolt.Sips.Types.TimeWithTZOffset{
      time: ~T[12:45:30.250000],
      timezone_offset: 3600
    }
  }
]

# Cartesian 2D point with Point
iex> point_cartesian_2D = Point.create(:cartesian, 50, 60.5)
%Bolt.Sips.Types.Point{
  crs: "cartesian",
  height: nil,
  latitude: nil,
  longitude: nil,
  srid: 7203,
  x: 50.0,
  y: 60.5,
  z: nil
}
iex> Bolt.Sips.query!(conn, "RETURN point($pt) AS pt", %{pt: point_cartesian_2D})
[
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

# Geographic 2D point with Point
iex> point_geo_2D = Point.create(:wgs_84, 50, 60.5)
%Bolt.Sips.Types.Point{
  crs: "wgs-84",
  height: nil,
  latitude: 60.5,
  longitude: 50.0,
  srid: 4326,
  x: 50.0,
  y: 60.5,
  z: nil
}
iex> Bolt.Sips.query!(conn, "RETURN point($pt) AS pt", %{pt: point_geo_2D})
[
  %{
    "pt" => %Bolt.Sips.Types.Point{
      crs: "wgs-84",
      height: nil,
      latitude: 60.5,
      longitude: 50.0,
      srid: 4326,
      x: 50.0,
      y: 60.5,
      z: nil
    }
  }
]

# Cartesian 3D point with Point
iex> point_cartesian_3D = Point.create(:cartesian, 50, 60.5, 12.34)
%Bolt.Sips.Types.Point{
  crs: "cartesian-3d",
  height: nil,
  latitude: nil,
  longitude: nil,
  srid: 9157,
  x: 50.0,
  y: 60.5,
  z: 12.34
}
iex> Bolt.Sips.query!(conn, "RETURN point($pt) AS pt", %{pt: point_cartesian_3D})
[
  %{
    "pt" => %Bolt.Sips.Types.Point{
      crs: "cartesian-3d",
      height: nil,
      latitude: nil,
      longitude: nil,
      srid: 9157,
      x: 50.0,
      y: 60.5,
      z: 12.34
    }
  }
]

# Geographic 2D point with Point
iex> point_geo_3D = Point.create(:wgs_84, 50, 60.5, 12.34)
%Bolt.Sips.Types.Point{
  crs: "wgs-84-3d",
  height: 12.34,
  latitude: 60.5,
  longitude: 50.0,
  srid: 4979,
  x: 50.0,
  y: 60.5,
  z: 12.34
}
iex> Bolt.Sips.query!(conn, "RETURN point($pt) AS pt", %{pt: point_geo_2D})
[
  %{
    "pt" => %Bolt.Sips.Types.Point{
      crs: "wgs-84",
      height: nil,
      latitude: 60.5,
      longitude: 50.0,
      srid: 4326,
      x: 50.0,
      y: 60.5,
      z: nil
    }
  }
]
```
