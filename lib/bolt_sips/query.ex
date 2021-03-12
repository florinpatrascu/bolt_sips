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
  alias Bolt.Sips.{QueryStatement, Response, Types, Error, Exception}

  @cypher_seps ~r/;(.){0,1}\n/

  @spec query!(Bolt.Sips.conn(), String.t()) :: Response.t() | Exception.t()
  def query!(conn, statement), do: query!(conn, statement, %{})

  @spec query!(Bolt.Sips.conn(), String.t(), map, Keyword.t()) :: Response.t() | Exception.t()
  def query!(conn, statement, params, opts \\ []) when is_map(params) do
    with {:ok, r} <- query_commit(conn, statement, params, opts) do
      r
    else
      {:error, msg} ->
        raise Exception, message: msg

      e ->
        raise Exception, message: "unexpected error: #{inspect(e)}"
    end
  end

  @spec query(Bolt.Sips.conn(), String.t()) :: {:error, Error.t()} | {:ok, Response.t()}
  def query(conn, statement), do: query(conn, statement, %{})

  @spec query(Bolt.Sips.conn(), String.t(), map, Keyword.t()) ::
          {:error, Error.t()} | {:ok, Response.t()}
  def query(conn, statement, params, opts \\ []) when is_map(params) do
    case query_commit(conn, statement, params, opts) do
      {:error, message} -> {:error, %Error{message: message}}
      r -> r
    end
  rescue
    e in Bolt.Sips.Exception ->
      {:error, %Bolt.Sips.Error{code: e.code, message: e.message}}
  end

  ###########
  # Private #
  ###########
  @spec query_commit(Bolt.Sips.conn(), String.t(), map, Keyword.t()) ::
          {:error, Error.t()} | {:ok, Response.t()}
  defp query_commit(conn, statement, params, opts) do
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

    {:ok, commit!(errors, conn, statements, formated_params, opts)}
  rescue
    e in [RuntimeError, DBConnection.ConnectionError] ->
      {:error, Bolt.Sips.Error.new(e.message)}

    e in Exception ->
      {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)

      # n/a in newer Elixir version:
      # reraise e, __STACKTRACE__

      # using a safe call, for backward compatibility
      reraise e, stacktrace

    e ->
      {:error, e}
  end

  defp commit!([], conn, statements, formated_params, opts),
    do: tx!(conn, statements, formated_params, opts)

  defp commit!(errors, _conn, _statements, _formated_params, _opts),
    do: raise(Exception, message: "Unable to format params: #{inspect(errors)}")

  defp tx!(conn, [statement], params, opts), do: hd(send!(conn, statement, params, opts))

  # todo It returns [Response.t] !!!
  defp tx!(conn, statements, params, opts) when is_list(statements),
    do: Enum.reduce(statements, [], &send!(conn, &1, params, opts, &2))

  defp send!(conn, statement, params, opts, acc \\ [])

  @spec send!(Bolt.Sips.conn(), String.t(), Keyword.t(), map, list) ::
          {:error, Exception.t()} | [Response.t()] | RuntimeError
  defp send!(conn, statement, params, opts, acc) do
    # Retrieve timeout defined in config
    prefix = Keyword.get(opts, :prefix, :default)
    conf_timeout = Bolt.Sips.info()
    |> Map.get(prefix)
    |> Map.get(:user_options)
    |> Keyword.get(:timeout)

    opts = Keyword.put_new(opts, :timeout, conf_timeout)

    case DBConnection.execute(conn, %QueryStatement{statement: statement}, params, opts) do
      {:ok, _query, resp} ->
        with {:ok, %Response{} = r} <- Response.transform(resp) do
          acc ++ [r]
        else
          {:error, e} -> raise DBConnection.ConnectionError, message: e
        end

      {:error, %Bolt.Sips.Internals.Error{code: code, message: msg}} ->
        raise Exception, code: code, message: msg

      {:error, %{message: message}} ->
        raise DBConnection.ConnectionError, message: message
    end
  end

  # Format the param to be used in query
  # must return a tuple of the form: {:ok, param} or {:error, param}
  # In order to let query_commit handle the error
  @spec format_param({String.t(), any()}) :: {String.t(), {:ok | :error, any()}}
  defp format_param({name, %Types.Duration{} = duration}),
    do: {name, Types.Duration.format_param(duration)}

  defp format_param({name, %Types.Point{} = point}), do: {name, Types.Point.format_param(point)}

  defp format_param({name, value}), do: {name, {:ok, value}}
end
