defmodule Bolt.Sips.Response do
  @moduledoc """
  Support for transforming a Bolt response to a list of Bolt.Sips.Types or arbitrary values.

  For example, a simple Cypher query like this:

      RETURN [10,11,21] AS arr

  will return: `%{"arr" => [10,11,21]}`, while a more complex one, say:

      MATCH p=({name:'Alice'})-[r:KNOWS]->({name:'Bob'}) RETURN r

  will return the following list:

      [%{"r" => %Bolt.Sips.Types.Relationship{end: 647, id: 495,
       properties: %{}, start: 646, type: "KNOWS"}}]

  Please check the Bolt.Sips.Types module for the structures supporting the Neo4j entities.

  Briefly, the entities implemented so far are:

  - Node
  - Relationship
  - UnboundRelationship
  - Path

  Note: the `Path` has also functionality for "drawing" a graph, from a given node-relationship path
  """

  @type t :: __MODULE__

  alias Bolt.Sips.Types.{
    Node,
    Relationship,
    UnboundRelationship,
    Path,
    Duration,
    DateTimeWithTZOffset,
    TimeWithTZOffset,
    Point
  }

  alias Bolt.Sips.{Success}

  require Logger
  require Integer

  # self contained graph entities
  # node
  @node 78
  # path
  @path 80
  # relationship
  @relationship 82
  # relationship without endpoints
  @unbound_relationship 114
  # Date
  @date 68
  # Time
  @time 84
  # Local time
  @local_time 116
  # Duration
  @duration 69
  # Local datetime
  @local_datetime 100
  # Datetime with offset
  @datetime_with_zone_offset 70
  # Datetime with zone id
  @datetime_with_zone_id 102
  # Point 2D
  @point2d 88
  # Point 3D
  @point3d 89

  @doc """
  transform a raw Bolt response to a list of Responses
  """
  def transform(raw, _stats \\ :no) do
    # IO.puts("bolt raw response: #{inspect Success.new(raw)}")
    case Success.new(raw) do
      {:ok, success} ->
        cond do
          success.notifications != nil ->
            [%{plan: success.plan, notifications: success.notifications}]

          length(success.fields) > 0 ->
            create_records(success.fields, success.records)

          true ->
            %{stats: success.stats, type: success.type}
            # success.profile != nil -> ...
        end

      {:error, failure} ->
        {:error, failure}

      _ ->
        raw
    end
  end

  # I am bad at naming functions .. they should be named for what they mean, not
  # for what they do ...
  defp create_records([], []), do: []

  defp create_records(fields, records) do
    records
    |> Enum.map(&get_entities/1)
    |> Enum.map(fn recs -> Enum.zip(fields, recs) end)
    |> Enum.map(fn data -> Enum.into(data, %{}) end)

    # |> one_or_many
  end

  # defp one_or_many(rows) when length(rows) == 1, do: List.first(rows)
  # defp one_or_many(rows), do: rows

  defp get_entities(records) do
    Enum.reduce(records, [], &traverse_record/2)
  end

  defp traverse_record(record, acc) do
    acc ++ [extract_types(record)]
  end

  defp extract_types([]), do: []

  defp extract_types(sig: @node, fields: fields) do
    n = [:id, :labels, :properties] |> Enum.zip(fields)
    struct(Node, n)
  end

  defp extract_types(sig: @relationship, fields: fields) do
    rel = [:id, :start, :end, :type, :properties] |> Enum.zip(fields)
    struct(Relationship, rel)
  end

  defp extract_types(sig: @date, fields: [days_since_epoch]) when is_integer(days_since_epoch) do
    Date.add(~D[1970-01-01], days_since_epoch)
  end

  defp extract_types(sig: @time, fields: [time_since_epoch, offset])
       when is_integer(time_since_epoch) and is_integer(offset) do
    %TimeWithTZOffset{
      time: Time.add(~T[00:00:00.000], time_since_epoch, :nanosecond),
      timezone_offset: offset
    }
  end

  defp extract_types(sig: @local_time, fields: [time]) when is_integer(time) do
    Time.add(~T[00:00:00.000], time, :nanosecond)
  end

  defp extract_types(sig: @duration, fields: [months, days, seconds, nanoseconds])
       when is_integer(months) and is_integer(days) and is_integer(seconds) and
              is_integer(nanoseconds) do
    Duration.create(months, days, seconds, nanoseconds)
  end

  defp extract_types(sig: @local_datetime, fields: [seconds, nanoseconds])
       when is_integer(seconds) and is_integer(nanoseconds) do
    NaiveDateTime.add(
      ~N[1970-01-01 00:00:00.000],
      seconds * 1_000_000_000 + nanoseconds,
      :nanosecond
    )
  end

  defp extract_types(sig: @datetime_with_zone_offset, fields: [seconds, nanoseconds, offset])
       when is_integer(seconds) and is_integer(nanoseconds) and is_integer(offset) do
    naive_dt =
      NaiveDateTime.add(
        ~N[1970-01-01 00:00:00.000],
        seconds * 1_000_000_000 + nanoseconds,
        :nanosecond
      )

    %DateTimeWithTZOffset{naive_datetime: naive_dt, timezone_offset: offset}
  end

  defp extract_types(sig: @datetime_with_zone_id, fields: [seconds, nanoseconds, zone_id])
       when is_integer(seconds) and is_integer(nanoseconds) and is_bitstring(zone_id) do
    naive_dt =
      NaiveDateTime.add(
        ~N[1970-01-01 00:00:00.000],
        seconds * 1_000_000_000 + nanoseconds,
        :nanosecond
      )

    Bolt.Sips.TypesHelper.datetime_with_micro(naive_dt, zone_id)
  end

  defp extract_types(sig: @point2d, fields: [srid, x, y])
       when is_integer(srid) and is_float(x) and is_float(y) do
    Point.create(srid, x, y)
  end

  defp extract_types(sig: @point3d, fields: [srid, x, y, z])
       when is_integer(srid) and is_float(x) and is_float(y) and is_float(z) do
    Point.create(srid, x, y, z)
  end

  defp extract_types(sig: @path, fields: fields) do
    [ns, rs, sequence] = fields

    if length(ns) < 1 do
      raise "Invalid path. Must have some nodes"
    end

    # if Utils.mod(length(sequence), 2) != 0 do
    unless Integer.is_even(length(sequence)) do
      raise "Invalid path sequence. Must always consist of an even number of integers"
    end

    relationships = Enum.map(rs, &extract_types/1)
    nodes = Enum.map(ns, &extract_types/1)

    rel =
      [:nodes, :relationships, :sequence]
      |> Enum.zip([nodes, relationships, sequence])

    struct(Path, rel)
  end

  defp extract_types(sig: @unbound_relationship, fields: fields) do
    rel = [:id, :type, :properties] |> Enum.zip(fields)
    struct(UnboundRelationship, rel)
  end

  defp extract_types(r), do: extract_any(r, [])

  defp extract_any([], acc), do: Enum.reverse(acc)

  defp extract_any([h | t], acc) do
    extract_any(t, [extract_types(h)] ++ acc)
  end

  defp extract_any(r, acc) do
    if length(acc) > 0 do
      Logger.error("w⦿‿⦿t! Error: extract_any(#{inspect(r)}, #{inspect(acc)})")
    end

    r
  end
end
