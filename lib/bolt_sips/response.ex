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

  alias Bolt.Sips.Types.{Node, Relationship, UnboundRelationship, Path}
  alias Bolt.Sips.{Success, Error, Utils}

  require Logger
  require Integer

  @node                   78 # self-contained graph node
  @path                   80 # self-contained graph path
  @relationship           82 # self-contained graph relationship
  @unbound_relationship  114 # self-contained graph relationship without endpoints

  @doc """
  transform a raw Bolt response to a list of Responses

  todo: is this the best place for hooking in the stats, if any?
  """
  def transform(raw, stats \\ :no) do
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

      {:error, failure} -> {:error, failure}

      _ -> raw

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
  defp extract_types([sig: @node, fields: fields]) do
    node = [:id, :labels, :properties] |> Enum.zip(fields)
    struct(Node, node)
  end

  defp extract_types([sig: @relationship, fields: fields]) do
    rel = [:id, :start, :end, :type, :properties] |> Enum.zip(fields)
    struct(Relationship, rel)
  end

  defp extract_types([sig: @path, fields: fields]) do
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
    rel = [:nodes, :relationships, :sequence]
    |> Enum.zip([nodes, relationships, sequence])

    struct(Path, rel)
  end

  defp extract_types([sig: @unbound_relationship, fields: fields]) do
    rel = [:id, :type, :properties] |> Enum.zip(fields)
    struct(UnboundRelationship, rel)
  end

  defp extract_types(r), do: extract_any(r, [])

  defp extract_any([], acc), do: Enum.reverse(acc)
  defp extract_any([h|t], acc) do
    extract_any(t, [extract_types(h)] ++ acc)
  end
  defp extract_any(r, acc) do
    if length(acc) > 0 do
      IO.puts("w⦿‿⦿t! Error: extract_any(#{inspect r}, #{inspect acc})")
    end
    r
  end

end
