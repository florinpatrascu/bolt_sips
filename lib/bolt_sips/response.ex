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

  Note: the `Path` has also functionality for "drawing" a graph, from a given node-relationship path
  """

  @type t :: __MODULE__

  alias Bolt.Sips.{Success}

  require Logger
  require Integer

  @doc false
  # transform a raw Bolt response to a list of Responses
  def transform(raw, _stats \\ :no) do
    # IO.puts("bolt raw response: #{inspect(raw)}")

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
    |> Enum.map(fn recs -> Enum.zip(fields, recs) end)
    |> Enum.map(fn data -> Enum.into(data, %{}) end)
  end
end
