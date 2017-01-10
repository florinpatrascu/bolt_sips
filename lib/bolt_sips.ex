defmodule Bolt.Sips do
  @moduledoc """
  A Neo4j Elixir driver wrapped around the Bolt protocol.
  """

  @pool_name :bolt_sips_pool
  @timeout   15_000
  # @max_rows     500

  alias Bolt.Sips.{Query, Transaction, Connection, Utils}

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
       Poolboy will block the current process and wait for an available worker,
       failing after a timeout, when the pool is full;
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
      {:ok, _pid} = Bolt.Sips.start_link(opts)

      conn = Bolt.Sips.conn
      Bolt.Sips.query!(conn, "CREATE (a:Person {name:'Bob'})")
      Bolt.Sips.query!(conn, "MATCH (a:Person) RETURN a.name AS name")
      |> Enum.map(&(&1["name"]))

  In the future we may use the `DBConnection` framework.
  """
  @spec start_link(Keyword.t) :: {:ok, pid} | {:error, Bolt.Sips.Error.t}
  def start_link(opts) do
    ConCache.start_link([], name: :bolt_sips_cache)

    cnf = Utils.default_config(opts)
    cnf = cnf |> Keyword.put(:socket, (if Keyword.get(cnf, :ssl), do: :etls, else: :gen_tcp))

    ConCache.put(:bolt_sips_cache, :config, cnf)

    poolboy_config = [
      name: {:local, @pool_name},
      worker_module: Bolt.Sips.Connection,
      size: Keyword.get(cnf, :pool_size),
      max_overflow: Keyword.get(cnf, :max_overflow)
    ]

    children = [:poolboy.child_spec(@pool_name, poolboy_config, cnf)]
    options = [strategy: :one_for_one, name: __MODULE__]

    Supervisor.start_link(children, options)
  end

  @doc false
  def child_spec(opts) do
    Supervisor.Spec.worker(__MODULE__, [opts])
  end


  @doc """
  returns a Bolt.Sips.Connection
  """
  defdelegate conn(), to: Connection

  ## Query
  ########################

  @doc """
  sends the query (and its parameters) to the server and returns `{:ok, Bolt.Sips.Response}` or
  `{:error, error}` otherwise
  """
  @spec query(Bolt.Sips.Connection, String.t) :: {:ok, Bolt.Sips.Response} | {:error, Bolt.Sips.Error}
  defdelegate query(conn, statement), to: Query

  @doc """
  The same as query/2 but raises a Bolt.Sips.Exception if it fails.
  Returns the server response otherwise.
  """
  @spec query!(Bolt.Sips.Connection, String.t) :: Bolt.Sips.Response | Bolt.Sips.Exception
  defdelegate query!(conn, statement), to: Query

  @doc """
  send a query and an associated map of parameters. Returns the server response or an error
  """
  @spec query(Bolt.Sips.Connection, String.t, Map.t) :: {:ok, Bolt.Sips.Response} | {:error, Bolt.Sips.Error}
  defdelegate query(conn, statement, params), to: Query

  @doc """
  The same as query/3 but raises a Bolt.Sips.Exception if it fails.
  """
  @spec query!(Bolt.Sips.Connection, String.t, Map.t) :: Bolt.Sips.Response | Bolt.Sips.Exception
  defdelegate query!(conn, statement, params), to: Query


  ## Transaction
  ########################

  @doc """
  begin a new transaction.
  """
  @spec begin(Bolt.Sips.Connection) :: Bolt.Sips.Connection
  defdelegate begin(conn), to: Transaction

  @doc """
  given you have an open transaction, you can use this to send a commit request
  """
  @spec commit(Bolt.Sips.Connection) :: Bolt.Sips.Response
  defdelegate commit(conn), to: Transaction

  @doc """
  given that you have an open transaction, you can send a rollback request.
  The server will rollback the transaction. Any further statements trying to run
  in this transaction will fail immediately.
  """
  @spec rollback(Bolt.Sips.Connection) :: Bolt.Sips.Connection
  defdelegate rollback(conn), to: Transaction

  @doc """
  returns an environment specific Bolt.Sips configuration.
  """
  def config(), do: ConCache.get(:bolt_sips_cache, :config)

  @doc false
  def config(key), do: Keyword.get(config(), key)

  @doc false
  def config(key, default) do
    try do
      Keyword.get(config(), key, default)
    rescue
      _ -> default
    end
  end

  @doc false
  def pool_name, do: @pool_name

  @doc false
  def init(opts) do
    {:ok, opts}
  end

  ## Helpers
  ######################

  # defp defaults(opts) do
  #   Keyword.put_new(opts, :timeout, @timeout)
  # end
end
