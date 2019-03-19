defmodule Bolt.Sips.Query do
  @moduledoc """
  Provides a simple Query DSL.

  You can run simple Cypher queries with or w/o parameters, for example:

      {:ok, row} = Bolt.Sips.query(conn, "match (n:Person {bolt_sips: true}) return n.name as Name limit 5")
      assert List.first(row)["Name"] == "Patrick Rothfuss"

  Or more complex ones:

      cypher = \"""
      MATCH (p:Person {bolt_sips: true})
      RETURN p, p.name AS name, upper(p.name) as NAME,
             coalesce(p.nickname,"n/a") AS nickname,
             { name: p.name, label:head(labels(p))} AS person
      \"""
      {:ok, r} = Bolt.Sips.query(conn, cypher)

  As you can see, you can organize your longer queries using the Elixir multiple line conventions, for readability.

  And there is one more trick, you can use for more complex Cypher commands: use `;` as a transactional separator.

  For example, say you want to clean up the test database **before** creating some tests entities. You can do that like this:

      cypher = \"""
      MATCH (n {bolt_sips: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r;

      CREATE (BoltSips:BoltSips {title:'Elixir sipping from Neo4j, using Bolt', released:2016, license:'MIT', bolt_sips: true})
      CREATE (TNOTW:Book {title:'The Name of the Wind', released:2007, genre:'fantasy', bolt_sips: true})
      CREATE (Patrick:Person {name:'Patrick Rothfuss', bolt_sips: true})
      CREATE (Kvothe:Person {name:'Kote', bolt_sips: true})
      CREATE (Denna:Person {name:'Denna', bolt_sips: true})
      CREATE (Chandrian:Deamon {name:'Chandrian', bolt_sips: true})

      CREATE
        (Kvothe)-[:ACTED_IN {roles:['sword fighter', 'magician', 'musician']}]->(TNOTW),
        (Denna)-[:ACTED_IN {roles:['many talents']}]->(TNOTW),
        (Chandrian)-[:ACTED_IN {roles:['killer']}]->(TNOTW),
        (Patrick)-[:WROTE]->(TNOTW)
      \"""
      assert {:ok, _r} = Bolt.Sips.query(conn, cypher)

  In the example above, this command: `MATCH (n {bolt_sips: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r;` will be executed in a distinct transaction, before all the other queries

  See the various tests, or more examples and implementation details.

  """
  alias Bolt.Sips
  alias Bolt.Sips.{QueryStatement, Response, Types, Exception}

  @cypher_seps ~r/;(.){0,1}\n/

  def query!(conn, statement), do: query!(conn, statement, %{})

  def query!(conn, statement, params) when is_map(params) do
    case query_commit(conn, statement, params) do
      {:error, f} ->
        raise Exception, code: f.code, message: f.message

      r ->
        r
    end
  end

  def query(conn, statement), do: query(conn, statement, %{})

  def query(conn, statement, params) when is_map(params) do
    case query_commit(conn, statement, params) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
    end
  end

  defp query_commit(conn, statement, params) do
    statements =
      String.split(statement, @cypher_seps, trim: true)
      |> Enum.map(&String.trim(&1))
      |> Enum.filter(&(String.length(&1) > 0))

    formated_params =
      params
      |> Enum.map(&format_param/1)
      |> Enum.map(fn {k, {:ok, value}} -> {k, value} end)
      |> Map.new()

    errors =
      formated_params
      |> Enum.filter(fn {_, formated} ->
        case formated do
          {:error, _} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn {k, {:error, error}} -> {k, error} end)

    if length(errors) == 0 do
      tx(conn, statements, formated_params)
    else
      {:error, %Sips.Error{message: "Unable to format params: #{inspect(errors)}"}}
    end
  end

  # Format the param to be used in query
  # must return a tuple of the form: {:ok, param} or {:error, param}
  # In order to let querey_commit handle the error
  @spec format_param({String.t(), any()}) :: {String.t(), {:ok | :error, any()}}
  defp format_param({name, %Types.Duration{} = duration}) do
    {name, Types.Duration.format_param(duration)}
  end

  defp format_param({name, %Types.Point{} = point}) do
    {name, Types.Point.format_param(point)}
  end

  defp format_param({name, value}), do: {name, {:ok, value}}

  defp tx(conn, statements, params) when length(statements) == 1 do
    exec = fn conn ->
      q = %QueryStatement{statement: hd(statements)}

      case DBConnection.execute(conn, q, params) do
        {:ok, _query, resp} -> resp
        other -> other
      end
    end

    Response.transform(DBConnection.run(conn, exec, run_opts()))
  end

  defp tx(conn, statements, params) do
    exec = fn conn ->
      Enum.reduce(statements, [], &send!(conn, &1, params, &2))
    end

    DBConnection.run(conn, exec, run_opts())
  rescue
    e in RuntimeError ->
      {:error, e}
  end

  defp send!(conn, statement, params, acc) do
    case DBConnection.execute(conn, %QueryStatement{statement: statement}, params) do
      {:ok, _query, resp} -> acc ++ [Response.transform(resp)]
      {:error, error} -> raise RuntimeError, error
    end
  end

  defp run_opts do
    [pool: Sips.config(:pool)]
  end
end
