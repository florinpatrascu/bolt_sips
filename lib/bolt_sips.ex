defmodule Bolt.Sips do
  @moduledoc """
  A Neo4j Elixir driver wrapped around the Bolt protocol.
  """

  use Supervisor

  @registry_name :bolt_sips_registry

  @timeout 15_000
  # @max_rows     500

  alias Bolt.Sips.{Query, ConnectionSupervisor, Router, Error, Response, Exception}

  @type conn :: DBConnection.conn()
  @type transaction :: DBConnection.t()

  @doc """
  Start the connection process and connect to Neo4j

  ## Options:
    - `:url` - If present, it will be used for extracting the host name, the port and the authentication details and will override the: hostname, port, username and the password, if these were already defined! Since this driver is devoted to the Bolt protocol only, the protocol if present in the url will be ignored and considered by default `bolt://`
    - `:hostname` - Server hostname (default: NEO4J_HOST env variable, then localhost);
    - `:port` - Server port (default: NEO4J_PORT env variable, then 7687);
    - `:username` - Username;
    - `:password` - User password;
    - `:pool_size` - maximum pool size;
    - `:max_overflow` - maximum number of workers created if pool is empty
    - `:timeout` - Connect timeout in milliseconds (default: `#{@timeout}`)
    - `:retry_linear_backoff` -  with Bolt, the initial handshake sequence (happening before sending any commands to the server) is represented by two important calls, executed in sequence: `handshake` and `init`, and they must both succeed, before sending any (Cypher) requests. You can see the details in the [Bolt protocol](http://boltprotocol.org/v1/#handshake) specs. This sequence is also sensitive to latencies, such as: network latencies, busy servers, etc., and because of that we're introducing a simple support for retrying the handshake (and the subsequent requests) with a linear backoff, and try the handshake sequence (or the request) a couple of times before giving up. See examples below.

  ## Example of valid configurations (i.e. defined in config/dev.exs) and usage:

      config :bolt_sips, Bolt,
        url: 'bolt://demo:demo@hobby-wowsoeasy.dbs.graphenedb.com:24786',
        ssl: true

      config :bolt_sips, Bolt,
        url: "bolt://Bilbo:Baggins@hobby-hobbits.dbs.graphenedb.com:24786",
        ssl: true,
        timeout: 15_000,
        retry_linear_backoff: [delay: 150, factor: 2, tries: 3]

      config :bolt_sips, Bolt,
        hostname: 'localhost',
        basic_auth: [username: "neo4j", password: "*********"],
        port: 7687,
        pool_size: 5,
        max_overflow: 1

  Sample code:

      opts = Application.get_env(:bolt_sips, Bolt)
      {:ok, pid} = Bolt.Sips.start_link(opts)

      Bolt.Sips.query!(pid, "CREATE (a:Person {name:'Bob'})")
      Bolt.Sips.query!(pid, "MATCH (a:Person) RETURN a.name AS name")
      |> Enum.map(&(&1["name"]))
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
          |> List.first()

        assert %{"b" => g_o_t} = book
        assert g_o_t.properties["title"] == "The Game Of Trolls"
        Bolt.Sips.rollback(conn, :changed_my_mind)
      end)

      books = Bolt.Sips.query!(main_conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")
      assert length(books) == 0
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

      {:error, :oops} = Bolt.Sips.transaction(pool, fun(conn) ->
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
