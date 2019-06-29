defmodule Bolt.Sips.Response do
  @moduledoc """
  Support for transforming a Bolt response to a list of Bolt.Sips.Types or arbitrary values.
  A Bolt.Sips.Response is used for mapping any response received from a Neo4j server into a an Elixir struct.

  You'll interact with this module every time you're needing to get and manipulate the data resulting from your queries.

  For example, a simple Cypher query like this:

      Bolt.Sips.query(Bolt.Sips.conn(), "RETURN [10,11,21] AS arr")


  will return:

      {:ok,
       %Bolt.Sips.Response{
        bookmark: "neo4j:bookmark:v1:tx21868",
        fields: ["arr"],
        notifications: [],
        plan: nil,
        profile: nil,
        records: [[[10, 11, 21]]],
        results: [%{"arr" => [10, 11, 21]}],
        stats: [],
        type: "r"
       }}

  and while you have now access to the full data returned by Neo4j, most of the times you'll just want the results:

      iex» %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(Bolt.Sips.conn(), "RETURN [10,11,21] AS arr")
      iex» results
      [%{"arr" => [10, 11, 21]}]

  More complex queries, i.e.:

      MATCH p=({name:'Alice'})-[r:KNOWS]->({name:'Bob'}) RETURN r

  will return `results` like this:

      [%{"r" => %Bolt.Sips.Types.Relationship{end: 647, id: 495,
       properties: %{}, start: 646, type: "KNOWS"}}]

  Note: the `Path` has also functionality for "drawing" a graph, from a given node-relationship path

  Our Bolt.Sips.Response is implementing Elixir's [Enumerable Protocol](https://hexdocs.pm/elixir/Enumerable.html), to help you accessing the results. Hence something like this, is possible:

      iex» Bolt.Sips.query!(Bolt.Sips.conn(), "RETURN [10,11,21] AS arr") |>
      ...» Enum.reduce(0, &(Enum.sum(&1["arr"]) + &2))
      42

  an overly complicated example, but you get the point?! :)

  You can also quickly get the `first` of the results, returned by Neo4j. Example:

      iex» Bolt.Sips.query!(Bolt.Sips.conn(), "UNWIND range(1, 10) AS n RETURN n") |>
      ...» Bolt.Sips.Response.first()
      %{"n" => 1}
  """

  @type t :: %__MODULE__{
          results: list,
          fields: list,
          records: list,
          plan: map,
          notifications: list,
          stats: list,
          profile: any,
          type: String.t(),
          bookmark: String.t()
        }

  @type key :: any
  @type value :: any
  @type acc :: any
  @type element :: any

  defstruct results: [],
            fields: nil,
            records: [],
            plan: nil,
            notifications: [],
            stats: [],
            profile: nil,
            type: nil,
            bookmark: nil

  alias Bolt.Sips.Error

  require Logger
  require Integer

  def first(%__MODULE__{results: []}), do: nil
  def first(%__MODULE__{results: [head | _tail]}), do: head

  @doc false
  # transform a raw Bolt response to a list of Responses
  def transform!(records, stats \\ :no) do
    with {:ok, %__MODULE__{} = records} <- transform(records, stats) do
      records
    else
      e -> e
    end
  end

  def transform(records, _stats \\ :no) do
    # records |> IO.inspect(label: "raw>> lib/bolt_sips/response.ex:44")

    with %__MODULE__{fields: fields, records: records} = response <- parse(records) do
      {:ok, %__MODULE__{response | results: create_results(fields, records)}}
    else
      e -> {:error, e}
    end
  rescue
    e in Bolt.Sips.Exception -> {:error, e.message}
    e -> {:error, e}
  end

  def fetch(%Bolt.Sips.Response{fields: fields, results: results}, key) do
    with true <- Enum.member?(fields, key) do
      findings =
        Enum.map(results, fn map ->
          Map.get(map, key)
        end)
        |> Enum.filter(&(&1 != nil))

      {:ok, findings}
    else
      _ -> nil
    end
  end

  def fetch!(%Bolt.Sips.Response{} = r, key) do
    with {:ok, findings} = fetch(r, key) do
      findings
    end
  end

  defp parse(records) do
    with {err_type, error} when err_type in ~w(halt error failure)a <- Error.new(records) do
      {:error, error}
    else
      records ->
        response =
          records
          |> Enum.reduce(%__MODULE__{}, fn {type, record}, acc ->
            with {:error, e} <- parse_record(type, record, acc) do
              raise Bolt.Sips.Exception, e
            else
              acc -> acc
            end
          end)

        %__MODULE__{response | records: response.records |> :lists.reverse()}
    end
  end

  # defp parse_record(:success, %{"fields" => fields, "t_first" => 0}, response) do
  defp parse_record(:success, %{"fields" => fields}, response) do
    %{response | fields: fields}
  end

  defp parse_record(:success, %{"profile" => profile, "stats" => stats, "type" => type}, response) do
    %{response | profile: profile, stats: stats, type: type}
  end

  defp parse_record(:success, %{"notifications" => n, "plan" => plan, "type" => type}, response) do
    %{response | plan: plan, notifications: n, type: type}
  end

  defp parse_record(:success, %{"plan" => plan, "type" => type}, response) do
    %{response | plan: plan, type: type}
  end

  defp parse_record(:success, %{"stats" => stats, "type" => type}, response) do
    %{response | stats: stats, type: type}
  end

  defp parse_record(:success, %{"bookmark" => bookmark, "type" => type}, response) do
    %{response | bookmark: bookmark, type: type}
  end

  defp parse_record(:success, %{"type" => type}, response) do
    %{response | type: type}
  end

  defp parse_record(:success, %{}, response) do
    %{response | type: "boltkit?"}
  end

  defp parse_record(:success, record, _response) do
    line =
      "; around: #{
        String.replace_leading("#{__ENV__.file}", "#{File.cwd!()}", "") |> Path.relative()
      }:#{__ENV__.line()}"

    err_msg = "UNKNOWN success type: " <> inspect(record) <> line
    Logger.error(err_msg)
    {:error, Bolt.Sips.Error.new(err_msg)}
  end

  # defp parse_record(:record, %{"bookmark" => "neo4j:bookmark:v1:tx14519", "t_last" => 1, "type" => "r"}, response) do

  defp parse_record(:record, record, response) do
    %{response | records: [record | response.records]}
  end

  defp parse_record(_type, record, _response) do
    line =
      "; around: #{
        String.replace_leading("#{__ENV__.file}", "#{File.cwd!()}", "") |> Path.relative()
      }:#{__ENV__.line()}"

    err_msg = "UNKNOWN `:record`: " <> inspect(record) <> line
    Logger.error(err_msg)
    {:error, Bolt.Sips.Error.new(err_msg)}
  end

  defp create_results(fields, records) do
    records
    |> Enum.map(fn recs -> Enum.zip(fields, recs) end)
    |> Enum.map(fn data -> Enum.into(data, %{}) end)
  end
end
