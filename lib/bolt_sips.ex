defmodule Bolt.Sips do
  @moduledoc """
  A Neo4j driver for Elixir providing many useful features:

  - using the Bolt protocol, the Elixir implementation - the Neo4j's newest network protocol, designed for high-performance; latest Bolt versions, are supported.
  - Can connect to a standalone Neo4j server (`:direct` mode) or to a Neo4j causal cluster, using the `bolt+routing` or the newer `neo4j` schemes; connecting in `:routing` mode.
  - Provides the user with the ability to create and manage distinct ad-hoc `role-based` connections to one or more Neo4j servers/databases
  - Supports transactions, simple and complex Cypher queries with or w/o parameters
  - Multi-tenancy
  - Supports Neo4j versions: 3.0.x/3.1.x/3.2.x/3.4.x/3.5.x

  To start, add the `:bolt_sips` dependency to you project, run `mix do deps.get, compile` on it and then you can quickly start experimenting with Neo4j from the convenience of your IEx shell. Example:

      iex» {:ok, _neo} = Bolt.Sips.start_link(url: "bolt://neo4j:test@localhost")
      {:ok, #PID<0.250.0>}
      iex»   conn = Bolt.Sips.conn()
      #PID<0.256.0>
      iex» Bolt.Sips.query!(conn, "RETURN 1 as n")
      %Bolt.Sips.Response{
        records: [[1]],
        results: [%{"n" => 1}]
      }

  the example above presumes that you have a Neo4j server available locally, using the Bolt protocol and requiring authentication.
  """

  use Supervisor

  @registry_name :bolt_sips_registry

  # @timeout 15_000
  # @max_rows     500

  alias Bolt.Sips.{Query, ConnectionSupervisor, Router, Error, Response, Exception}

  @type conn :: DBConnection.conn()
  @type transaction :: DBConnection.t()

  @doc """
  Start or add a new Neo4j connection

  ## Options:

  - `:url`- a full url to pointing to a running Neo4j server. Please remember you must specify the scheme used to connect to the server. Valid schemes:`bolt`,`bolt+routing`and`neo4j` - the last two being used for connecting to a Neo4j causal cluster.
  - `:pool_size` - the size of the connection pool. Default: 15
  - `:timeout` - a timeout value defined in milliseconds. Default: 15_000
  - `:ssl`-`true`, if the connection must be encrypted. Default:`false`
  - `:retry_linear_backoff`- the retry mechanism parameters. Also expected, the following parameters:`:delay`,`:factor`and`:tries`. Default value:`retry_linear_backoff: [delay: 150, factor: 2, tries: 3]`
  - `:prefix`- used for differentiating between multiple connections available in the same app. Default:`:default`

  ## Example of valid configurations (i.e. defined in config/dev.exs) and usage:

  This is the most basic configuration:

      config :bolt_sips, Bolt,
        url: "bolt://localhost:7687"

  and if you need to connect to remote servers:

      config :bolt_sips, Bolt,
        url: "bolt://Bilbo:Baggins@hobby-hobbits.dbs.graphenedb.com:24786",
        ssl: true,
        timeout: 15_000,
        retry_linear_backoff: [delay: 150, factor: 2, tries: 3]

  Example with a configuration defined in the `config/dev.exs`:

      opts = Application.get_env(:bolt_sips, Bolt)
      {:ok, pid} = Bolt.Sips.start_link(opts)

      Bolt.Sips.query!(pid, "CREATE (a:Person {name:'Bob'})")
      Bolt.Sips.query!(pid, "MATCH (a:Person) RETURN a.name AS name")
      |> Enum.map(&(&1["name"]))

  Or defining an ad-hoc configuration:

  Example with a configuration defined in the `config/dev.exs`:

      {:ok, _neo} = Bolt.Sips.start_link(url: "bolt://neo4j:test@localhost")

      conn = Bolt.Sips.conn()
      Bolt.Sips.query!(conn, "return 1 as n")

  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    with nil <- Process.whereis(__MODULE__) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    else
      pid ->
        Router.configure(opts)
        {:ok, pid}

      {pid, node} ->
        Router.configure(opts)
        {:ok, {pid, node}}
    end
  end

  @doc false
  def init(opts) do
    [
      Registry.child_spec(keys: :unique, name: registry_name()),
      ConnectionSupervisor,
      {Router, opts}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  @doc """
  Returns a pool name which can be used to acquire a connection from a pool of servers
  responsible with a specific type of operations: read, write and route, or all of the above: "direct"
  """
  @spec conn(atom, keyword) :: conn
  def conn(role \\ :direct, opts \\ [prefix: :default])
  def conn(role, opts)

  def conn(role, opts) do
    prefix = Keyword.get(opts, :prefix, :default)

    with {:ok, conn} <- Router.get_connection(role, prefix) do
      conn
    else
      {:error, e} ->
        raise Exception, e

      e ->
        {:error, e}
    end
  end

  ## Query
  ########################

  @doc """
  sends the query (and its parameters) to the server and returns `{:ok, Response.t()}` or
  `{:error, Error}` otherwise
  """
  @spec query(conn, String.t()) :: {:ok, Response.t() | [Response.t()]} | {:error, Error.t()}
  defdelegate query(conn, statement), to: Query

  @doc """
  The same as query/2 but raises a Exception if it fails.
  Returns the server response otherwise.
  """
  @spec query!(conn, String.t()) :: Response.t() | [Response.t()] | Exception.t()
  defdelegate query!(conn, statement), to: Query

  @doc """
  send a query and an associated map of parameters. Returns the server response or an error
  """
  @spec query(conn, String.t(), map()) ::
          {:ok, Response.t() | [Response.t()]} | {:error, Error.t()}
  defdelegate query(conn, statement, params), to: Query

  @doc """
  The same as query/3 but raises a Exception if it fails.
  """
  @spec query!(conn, String.t(), map()) :: Response.t() | [Response.t()] | Exception.t()
  defdelegate query!(conn, statement, params), to: Query

  ## Transaction
  ########################

  @doc """
    Example:

    ```elixir
    setup do
      {:ok, [main_conn: Bolt.Sips.conn()]}
    end

    test "execute statements in transaction", %{main_conn: main_conn} do
      Bolt.Sips.transaction(main_conn, fn conn ->
        book =
          Bolt.Sips.query!(conn, "CREATE (b:Book {title: \"The Game Of Trolls\"}) return b")
          |> Response.first()

        assert %{"b" => g_o_t} = book
        assert g_o_t.properties["title"] == "The Game Of Trolls"
        Bolt.Sips.rollback(conn, :changed_my_mind)
      end)

      books = Bolt.Sips.query!(main_conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")
      assert Enum.count(books) == 0
    end
    ```
  """

  defdelegate transaction(conn, fun, opts \\ []), to: DBConnection

  @doc """
  Rollback a database transaction and release lock on connection.

  When inside of a `transaction/3` call does a non-local return, using a
  `throw/1` to cause the transaction to enter a failed state and the
  `transaction/3` call returns `{:error, reason}`. If `transaction/3` calls are
  nested the connection is marked as failed until the outermost transaction call
  does the database rollback.

  ### Example

      {:error, :oops} = Bolt.Sips.transaction(pool, fn(conn) ->
        Bolt.Sips.rollback(conn, :oops)
      end)
  """
  @spec rollback(DBConnection.t(), reason :: any) :: no_return
  defdelegate rollback(conn, opts), to: DBConnection

  @doc """
  terminate a pool of connections with the role specified
  """
  defdelegate terminate_connections(role), to: Router

  @doc """
  peek into the main Router state, and return the internal state controlling the connections
  to the server/server. Mostly for internal use or for helping driver developers.
  """
  @spec info() :: map
  def info() do
    Bolt.Sips.Router.info()
  end

  @doc """
  extract the routing table from the router
  """
  @spec routing_table(any) :: map
  def routing_table(prefix \\ :default)

  def routing_table(prefix) do
    Bolt.Sips.Router.routing_table(prefix)
  end

  @doc """
  the registry name used across the various driver components
  """
  @spec registry_name() :: :bolt_sips_registry
  def registry_name(), do: @registry_name
end
