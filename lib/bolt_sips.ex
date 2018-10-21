defmodule Bolt.Sips do
  @moduledoc """
  A Neo4j Elixir driver wrapped around the Bolt protocol.
  """

  use Supervisor

  @pool_name :bolt_sips_pool
  @timeout 15_000
  # @max_rows     500

  alias Bolt.Sips.{Query, Utils, ConfigAgent}

  @type conn :: DBConnection.conn()
  @type transaction :: DBConnection.t()
  @type result :: {:ok, result :: any} | {:error, Exception.t()}

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
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(opts) do
    options = Utils.default_config(opts)
    ssl_or_sock = if(Keyword.get(options, :ssl), do: :ssl, else: Keyword.get(options, :socket))
    config = Keyword.put(options, :socket, ssl_or_sock)

    children = [
      {Bolt.Sips.ConfigAgent, config},
      DBConnection.child_spec(Bolt.Sips.Protocol, pool_config(config))
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Returns a pool name which can be used to acquire a connection.
  """
  def conn, do: pool_name()

  ## Query
  ########################

  @doc """
  sends the query (and its parameters) to the server and returns `{:ok, Bolt.Sips.Response}` or
  `{:error, error}` otherwise
  """
  @spec query(conn, String.t()) :: {:ok, Bolt.Sips.Response} | {:error, Bolt.Sips.Error}
  defdelegate query(conn, statement), to: Query

  @doc """
  The same as query/2 but raises a Bolt.Sips.Exception if it fails.
  Returns the server response otherwise.
  """
  @spec query!(conn, String.t()) :: Bolt.Sips.Response | Bolt.Sips.Exception
  defdelegate query!(conn, statement), to: Query

  @doc """
  send a query and an associated map of parameters. Returns the server response or an error
  """
  @spec query(conn, String.t(), Map.t()) :: {:ok, Bolt.Sips.Response} | {:error, Bolt.Sips.Error}
  defdelegate query(conn, statement, params), to: Query

  @doc """
  The same as query/3 but raises a Bolt.Sips.Exception if it fails.
  """
  @spec query!(conn, String.t(), Map.t()) :: Bolt.Sips.Response | Bolt.Sips.Exception
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

  @spec transaction(DBConnection.t(), (DBConnection.t() -> result), opts :: Keyword.t()) ::
          {:ok, result} | {:error, reason :: any}
        when result: var
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
  returns an environment specific Bolt.Sips configuration.
  """
  def config, do: ConfigAgent.get_config()

  @doc false
  def config(key), do: Keyword.get(config(), key)

  @doc false
  def config(key, default) do
    Keyword.get(config(), key, default)
  rescue
    _ -> default
  end

  @doc false
  def pool_name, do: @pool_name

  ## Helpers
  ######################

  defp pool_config(cnf) do
    [
      name: pool_name(),
      pool_size: Keyword.get(cnf, :pool_size),
      pool_overflow: Keyword.get(cnf, :max_overflow)
    ]
  end
end
