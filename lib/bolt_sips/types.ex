defmodule Bolt.Sips.Types do
  @moduledoc """
  Basic support for representing nodes, relationships and paths belonging to
  a Neo4j graph database.

  Four supported types of entities:

  - Node
  - Relationship
  - UnboundRelationship
  - Path

  More details, about the Bolt protocol, here:
  https://github.com/boltprotocol/boltprotocol/blob/master/README.md

  Additionally, since bolt V2, new types appears: spatial and temporal
  Those are not documented in bolt protocol, but neo4j documentation can be found here:
  https://neo4j.com/docs/cypher-manual/current/syntax/temporal/
  https://neo4j.com/docs/cypher-manual/current/syntax/spatial/

  To work with temporal types, the following Elixir structs are available:
  - Time, DateTime, NaiveDateTime
  - Calendar.DateTime to work with timezone (as string)
  - TimeWithTZOffset, DateTimeWithTZOffset to work with (date)time and timezone offset(as integer)
  - Duration

  For spatial types, you only need Point struct as it covers:
  - 2D point (cartesian or geographic)
  - 3D point (cartesian or geographic)
  """

  alias Bolt.Sips.TypesHelper

  defmodule Entity do
    @moduledoc """
      base structure for Node and Relationship
    """
    @base_fields [id: nil, properties: nil]
    defmacro __using__(fields) do
      fields = @base_fields ++ fields

      quote do
        defstruct unquote(fields)
      end
    end
  end

  defmodule Node do
    @moduledoc """
      Self-contained graph node.

      A Node represents a node from a Neo4j graph and consists of a
      unique identifier (within the scope of its origin graph), a list of
      labels and a map of properties.

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#node
    """

    use Entity, labels: nil
  end

  defmodule Relationship do
    @moduledoc """
      Self-contained graph relationship.

      A Relationship represents a relationship from a Neo4j graph and consists of
      a unique identifier (within the scope of its origin graph), identifiers
      for the start and end nodes of that relationship, a type and a map of properties.

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#relationship
    """

    use Entity, start: nil, end: nil, type: nil
  end

  defmodule UnboundRelationship do
    @moduledoc """
      Self-contained graph relationship without endpoints.
      An UnboundRelationship represents a relationship relative to a
      separately known start point and end point.

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#unboundrelationship
    """

    use Entity, start: nil, end: nil, type: nil
  end

  defmodule Path do
    @moduledoc """
      Self-contained graph path.

      A Path is a sequence of alternating nodes and relationships corresponding to a
      walk in the graph. The path always begins and ends with a node.
      Its representation consists of a list of distinct nodes,
      a list of distinct relationships and a sequence of integers describing the
      path traversal

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#path
    """
    @type t :: %__MODULE__{
            nodes: List.t() | nil,
            relationships: List.t() | nil,
            sequence: List.t() | nil
          }
    defstruct nodes: nil, relationships: nil, sequence: nil

    @doc """
    represents a traversal or walk through a graph and maintains a direction
    separate from that of any relationships traversed
    """
    @spec graph(Path.t()) :: List.t() | nil
    def graph(path) do
      entities = [List.first(path.nodes)]

      draw_path(
        path.nodes,
        path.relationships,
        path.sequence,
        0,
        Enum.take_every(path.sequence, 2),
        entities,
        # last node
        List.first(path.nodes),
        # next node
        nil
      )
    end

    # @lint false
    defp draw_path(_n, _r, _s, _i, [], acc, _ln, _nn), do: acc

    defp draw_path(n, r, s, i, [h | t] = _rel_index, acc, ln, _nn) do
      next_node = Enum.at(n, Enum.at(s, 2 * i + 1))

      urel =
        if h > 0 && h < 255 do
          # rel: rels[rel_index - 1], start/end: (ln.id, next_node.id)
          rel = Enum.at(r, h - 1)

          unbound_relationship =
            [:id, :type, :properties, :start, :end]
            |> Enum.zip([rel.id, rel.type, rel.properties, ln.id, next_node.id])

          struct(UnboundRelationship, unbound_relationship)
        else
          # rel: rels[-rel_index - 1], start/end: (next_node.id, ln.id)
          # Neo4j sends: -1, and Bolt.Sips.Internals. returns 255 instead? Investigating,
          # meanwhile ugly path:
          # oh dear ...
          haha = if h == 255, do: -1, else: h
          rel = Enum.at(r, -haha - 1)

          unbound_relationship =
            [:id, :type, :properties, :start, :end]
            |> Enum.zip([rel.id, rel.type, rel.properties, next_node.id, ln.id])

          struct(UnboundRelationship, unbound_relationship)
        end

      draw_path(n, r, s, i + 1, t, (acc ++ [urel]) ++ [next_node], next_node, ln)
    end
  end

  defmodule TimeWithTZOffset do
    @moduledoc """
    Manage a Time and its time zone offset.

    This temporal types hs been added in bolt v2
    """
    defstruct [:time, :timezone_offset]

    @type t :: %__MODULE__{
            time: Calendar.time(),
            timezone_offset: integer()
          }

    @doc """
    Create a valid TimeWithTZOffset from a Time and offset in seconds
    """
    @spec create(Calendar.time(), integer()) :: TimeWithTZOffset.t()
    def create(%Time{} = time, offset) when is_integer(offset) do
      %TimeWithTZOffset{
        time: time,
        timezone_offset: offset
      }
    end

    @doc """
    Convert TimeWithTZOffset struct in a cypher-compliant  string
    """
    @spec format_param(TimeWithTZOffset.t()) :: {:ok, String.t()} | {:error, any()}
    def format_param(%TimeWithTZOffset{time: time, timezone_offset: offset})
        when is_integer(offset) do
      param = Time.to_iso8601(time) <> TypesHelper.formated_time_offset(offset)
      {:ok, param}
    end

    def format_param(param) do
      {:error, param}
    end
  end

  defmodule DateTimeWithTZOffset do
    @moduledoc """
    Manage a Time and its time zone offset.

    This temporal types hs been added in bolt v2
    """
    defstruct [:naive_datetime, :timezone_offset]

    @type t :: %__MODULE__{
            naive_datetime: Calendar.naive_datetime(),
            timezone_offset: integer()
          }

    @doc """
    Create a valid DateTimeWithTZOffset from a NaiveDateTime and offset in seconds
    """
    @spec create(Calendar.naive_datetime(), integer()) :: DateTimeWithTZOffset.t()
    def create(%NaiveDateTime{} = naive_datetime, offset) when is_integer(offset) do
      %DateTimeWithTZOffset{
        naive_datetime: naive_datetime,
        timezone_offset: offset
      }
    end

    @doc """
    Convert DateTimeWithTZOffset struct in a cypher-compliant  string
    """
    @spec format_param(DateTimeWithTZOffset.t()) :: {:ok, String.t()} | {:error, any()}
    def format_param(%DateTimeWithTZOffset{naive_datetime: ndt, timezone_offset: offset})
        when is_integer(offset) do
      formated = NaiveDateTime.to_iso8601(ndt) <> TypesHelper.formated_time_offset(offset)
      {:ok, formated}
    end

    def format_param(param) do
      {:error, param}
    end
  end

  defmodule Duration do
    @moduledoc """
    a Duration type, as introduced in bolt V2.

    Composed of months, days, seconds and nanoseconds, it can be used in date operations
    """
    defstruct years: 0,
              months: 0,
              weeks: 0,
              days: 0,
              hours: 0,
              minutes: 0,
              seconds: 0,
              nanoseconds: 0

    @type t :: %__MODULE__{
            years: non_neg_integer(),
            months: non_neg_integer(),
            weeks: non_neg_integer(),
            days: non_neg_integer(),
            hours: non_neg_integer(),
            minutes: non_neg_integer(),
            seconds: non_neg_integer(),
            nanoseconds: non_neg_integer()
          }

    @period_prefix "P"
    @time_prefix "T"

    @year_suffix "Y"
    @month_suffix "M"
    @week_suffix "W"
    @day_suffix "D"
    @hour_suffix "H"
    @minute_suffix "M"
    @second_suffix "S"

    @doc """
    Create a Duration struct from data returned by Neo4j.

    Neo4j returns a list of 4 integers:
      - months
      - days
      - seconds
      - nanoseconds

    Struct elements are computed in a logical way, then for exmple 65 seconds is 1min and 5
    seconds. Beware that you may not retrieve the same data you send!
    Note: days are not touched as they are not a fixed number of days for each month.


    ## Example:

        iex> Duration.create(15, 53, 125, 54)
        %Bolt.Sips.Types.Duration{
          days: 53,
          hours: 0,
          minutes: 2,
          months: 3,
          nanoseconds: 54,
          seconds: 5,
          weeks: 0,
          years: 1
        }
    """
    @spec create(integer(), integer(), integer(), integer()) :: Duration.t()
    def create(months, days, seconds, nanoseconds)
        when is_integer(months) and is_integer(days) and is_integer(seconds) and
               is_integer(nanoseconds) do
      years = div(months, 12)
      months_ = rem(months, 12)
      {hours, minutes, seconds_inter} = TypesHelper.decompose_in_hms(seconds)
      {seconds_, nanoseconds_} = manage_nanoseconds(seconds_inter, nanoseconds)

      %Duration{
        years: years,
        months: months_,
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds_,
        nanoseconds: nanoseconds_
      }
    end

    @spec manage_nanoseconds(integer(), integer()) :: {integer(), integer()}
    defp manage_nanoseconds(seconds, nanoseconds) when nanoseconds >= 1_000_000_000 do
      seconds_ = seconds + div(nanoseconds, 1_000_000_000)
      nanoseconds_ = rem(nanoseconds, 1_000_000_000)
      {seconds_, nanoseconds_}
    end

    defp manage_nanoseconds(seconds, nanoseconds) do
      {seconds, nanoseconds}
    end

    @doc """
    Convert a %Duration in a cypher-compliant string.
    To know everything about duration format, please see:
    https://neo4j.com/docs/cypher-manual/current/syntax/temporal/#cypher-temporal-durations
    """
    @spec format_param(Duration.t()) :: {:ok, String.t()} | {:error, any()}
    def format_param(
          %Duration{
            years: y,
            months: m,
            days: d,
            hours: h,
            minutes: mm,
            seconds: s,
            nanoseconds: ss
          } = duration
        )
        when is_integer(y) and is_integer(m) and is_integer(d) and is_integer(h) and
               is_integer(mm) and is_integer(s) and is_integer(ss) do
      formated = format_date(duration) <> format_time(duration)

      param =
        case formated do
          "" -> ""
          formated_duration -> @period_prefix <> formated_duration
        end

      {:ok, param}
    end

    def format_param(param) do
      {:error, param}
    end

    @spec format_date(Duration.t()) :: String.t()
    defp format_date(%Duration{years: years, months: months, weeks: weeks, days: days}) do
      format_duration_part(years, @year_suffix) <>
        format_duration_part(months, @month_suffix) <>
        format_duration_part(weeks, @week_suffix) <> format_duration_part(days, @day_suffix)
    end

    @spec format_time(Duration.t()) :: String.t()
    defp format_time(%Duration{
           hours: hours,
           minutes: minutes,
           seconds: s,
           nanoseconds: ns
         })
         when hours > 0 or minutes > 0 or s > 0 or ns > 0 do
      {seconds, nanoseconds} = manage_nanoseconds(s, ns)
      nanoseconds_f = nanoseconds |> Integer.to_string() |> String.pad_leading(9, "0")
      seconds_f = "#{Integer.to_string(seconds)}.#{nanoseconds_f}" |> String.to_float()

      @time_prefix <>
        format_duration_part(hours, @hour_suffix) <>
        format_duration_part(minutes, @minute_suffix) <>
        format_duration_part(seconds_f, @second_suffix)
    end

    defp format_time(_) do
      ""
    end

    @spec format_duration_part(integer(), String.t()) :: String.t()
    defp format_duration_part(duration_part, suffix)
         when duration_part > 0 and is_bitstring(suffix) do
      "#{stringify_number(duration_part)}#{suffix}"
    end

    defp format_duration_part(_, _) do
      ""
    end

    @spec stringify_number(number()) :: String.t()
    defp stringify_number(number) when is_integer(number) do
      Integer.to_string(number)
    end

    defp stringify_number(number) do
      Float.to_string(number)
    end
  end

  defmodule Point do
    @moduledoc """
    Manage spatial data introduced in Bolt V2

    Point can be:
      - Cartesian 2D
      - Geographic 2D
      - Cartesian 3D
      - Geographic 3D
    """
    @srid_cartesian 7203
    @srid_cartesian_3d 9157
    @srid_wgs_84 4326
    @srid_wgs_84_3d 4979

    defstruct [:crs, :srid, :x, :y, :z, :longitude, :latitude, :height]

    @type t :: %__MODULE__{
            crs: String.t(),
            srid: integer(),
            x: number() | nil,
            y: number() | nil,
            z: number() | nil,
            longitude: number() | nil,
            latitude: number() | nil,
            height: number() | nil
          }

    defguardp is_crs(crs) when crs in ["cartesian", "cartesian-3d", "wgs-84", "wgs-84-3d"]

    defguardp is_srid(srid)
              when srid in [@srid_cartesian, @srid_cartesian_3d, @srid_wgs_84, @srid_wgs_84_3d]

    defguardp are_coords(lt, lg, h, x, y, z)
              when (is_number(lt) or is_nil(lt)) and (is_number(lg) or is_nil(lg)) and
                     (is_number(h) or is_nil(h)) and (is_number(x) or is_nil(x)) and
                     (is_number(y) or is_nil(y)) and (is_number(z) or is_nil(z))

    defguardp is_valid_coords(x, y) when is_number(x) and is_number(y)
    defguardp is_valid_coords(x, y, z) when is_number(x) and is_number(y) and is_number(z)

    @doc """
    A 2D point either needs:
    - 2 coordinates and a atom (:cartesian or :wgs_84) to define its type
    - 2 coordinates and a srid (4326 or 7203) to define its type

    ## Examples:
        iex> Point.create(:cartesian, 10, 20.0)
        %Bolt.Sips.Types.Point{
          crs: "cartesian",
          height: nil,
          latitude: nil,
          longitude: nil,
          srid: 7203,
          x: 10.0,
          y: 20.0,
          z: nil
        }
        iex> Point.create(4326, 10, 20.0)
        %Bolt.Sips.Types.Point{
          crs: "wgs-84",
          height: nil,
          latitude: 20.0,
          longitude: 10.0,
          srid: 4326,
          x: 10.0,
          y: 20.0,
          z: 30.0
        }
    """
    @spec create(:cartesian | :wgs_84 | 4326 | 7203, number(), number()) :: Point.t()
    def create(:cartesian, x, y) do
      create(@srid_cartesian, x, y)
    end

    def create(:wgs_84, longitude, latitude) do
      create(@srid_wgs_84, longitude, latitude)
    end

    def create(@srid_cartesian, x, y) when is_valid_coords(x, y) do
      %Point{
        crs: crs(@srid_cartesian),
        srid: @srid_cartesian,
        x: format_coord(x),
        y: format_coord(y)
      }
    end

    def create(@srid_wgs_84, longitude, latitude) when is_valid_coords(longitude, latitude) do
      %Point{
        crs: crs(@srid_wgs_84),
        srid: @srid_wgs_84,
        x: format_coord(longitude),
        y: format_coord(latitude),
        longitude: format_coord(longitude),
        latitude: format_coord(latitude)
      }
    end

    @doc """
    Create a 3D point

    A 3D point either needs:
    - 3 coordinates and a atom (:cartesian or :wgs_84) to define its type
    - 3 coordinates and a srid (4979 or 9147) to define its type

    ## Examples:
        iex> Point.create(:cartesian, 10, 20.0, 30)
        %Bolt.Sips.Types.Point{
          crs: "cartesian-3d",
          height: nil,
          latitude: nil,
          longitude: nil,
          srid: 9157,
          x: 10.0,
          y: 20.0,
          z: 30.0
        }
        iex> Point.create(4979, 10, 20.0, 30)
        %Bolt.Sips.Types.Point{
          crs: "wgs-84-3d",
          height: 30.0,
          latitude: 20.0,
          longitude: 10.0,
          srid: 4979,
          x: 10.0,
          y: 20.0,
          z: 30.0
        }
    """
    @spec create(:cartesian | :wgs_84 | 4979 | 9157, number(), number(), number()) :: Point.t()
    def create(:cartesian, x, y, z) do
      create(@srid_cartesian_3d, x, y, z)
    end

    def create(:wgs_84, longitude, latitude, height) do
      create(@srid_wgs_84_3d, longitude, latitude, height)
    end

    def create(@srid_cartesian_3d, x, y, z) when is_valid_coords(x, y, z) do
      %Point{
        crs: crs(@srid_cartesian_3d),
        srid: @srid_cartesian_3d,
        x: format_coord(x),
        y: format_coord(y),
        z: format_coord(z)
      }
    end

    def create(@srid_wgs_84_3d, longitude, latitude, height)
        when is_valid_coords(longitude, latitude, height) do
      %Point{
        crs: crs(@srid_wgs_84_3d),
        srid: @srid_wgs_84_3d,
        x: format_coord(longitude),
        y: format_coord(latitude),
        z: format_coord(height),
        longitude: format_coord(longitude),
        latitude: format_coord(latitude),
        height: format_coord(height)
      }
    end

    @spec crs(4326 | 4979 | 7203 | 9157) :: String.t()
    defp crs(@srid_cartesian), do: "cartesian"
    defp crs(@srid_cartesian_3d), do: "cartesian-3d"
    defp crs(@srid_wgs_84), do: "wgs-84"
    defp crs(@srid_wgs_84_3d), do: "wgs-84-3d"

    defp format_coord(coord) when is_integer(coord), do: coord / 1
    defp format_coord(coord), do: coord

    @doc """
    Convert a Point struct into a cypher-compliant map

    ## Example
        iex(8)> Point.create(4326, 10, 20.0) |> Point.format_to_param
        %{crs: "wgs-84", latitude: 20.0, longitude: 10.0, x: 10.0, y: 20.0}
    """
    @spec format_param(Point.t()) :: {:ok, map()} | {:error, any()}
    def format_param(
          %Point{crs: crs, srid: srid, latitude: lt, longitude: lg, height: h, x: x, y: y, z: z} =
            point
        )
        when is_crs(crs) and is_srid(srid) and are_coords(lt, lg, h, x, y, z) do
      param =
        point
        |> Map.from_struct()
        |> Enum.filter(fn {_, val} -> not is_nil(val) end)
        |> Map.new()
        |> Map.drop([:srid])

      {:ok, param}
    end

    def format_param(param) do
      {:error, param}
    end
  end
end
