defmodule Bolt.Sips do
  @moduledoc """
  A Neo4j Elixir driver wrapped around the Bolt protocol.
  """

  use Supervisor

  @pool_name :bolt_sips_pool
  @timeout   15_000
  # @max_rows     500

  alias Bolt.Sips.{Query, Transaction, Utils, ConfigAgent}

  @type conn :: DBConnection.conn
  @type transaction :: DBConnection.t

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
      {:ok, pid} = Bolt.Sips.start_link(opts)

      Bolt.Sips.query!(pid, "CREATE (a:Person {name:'Bob'})")
      Bolt.Sips.query!(pid, "MATCH (a:Person) RETURN a.name AS name")
      |> Enum.map(&(&1["name"]))
  """
  @spec start_link(Keyword.t) :: Supervisor.on_start
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(opts) do
    ssl = if System.get_env("BOLT_WITH_ETLS"), do: :etls, else: :ssl
    cnf = Utils.default_config(opts)
    cnf = cnf |> Keyword.put(
      :socket,
      (if Keyword.get(cnf, :ssl), do: ssl, else: Keyword.get(cnf, :socket))
    )

    children = [
      {Bolt.Sips.ConfigAgent, cnf},
      DBConnection.child_spec(Bolt.Sips.Protocol, pool_config(cnf))
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
  @spec query(conn, String.t) ::
    {:ok, Bolt.Sips.Response} | {:error, Bolt.Sips.Error}
  defdelegate query(conn, statement), to: Query

  @doc """
  The same as query/2 but raises a Bolt.Sips.Exception if it fails.
  Returns the server response otherwise.
  """
  @spec query!(conn, String.t) ::
    Bolt.Sips.Response | Bolt.Sips.Exception
  defdelegate query!(conn, statement), to: Query

  @doc """
  send a query and an associated map of parameters. Returns the server response or an error
  """
  @spec query(conn, String.t, Map.t) ::
    {:ok, Bolt.Sips.Response} | {:error, Bolt.Sips.Error}
  defdelegate query(conn, statement, params), to: Query

  @doc """
  The same as query/3 but raises a Bolt.Sips.Exception if it fails.
  """
  @spec query!(conn, String.t, Map.t) ::
    Bolt.Sips.Response | Bolt.Sips.Exception
  defdelegate query!(conn, statement, params), to: Query

  ## Transaction
  ########################

  @doc """
  begin a new transaction.
  """
  @spec begin(conn) :: transaction | {:error, Exception.t}
  defdelegate begin(conn), to: Transaction

  @doc """
  given you have an open transaction, you can use this to send a commit request
  """
  @spec commit(transaction) :: Transaction.result
  defdelegate commit(transaction), to: Transaction

  @doc """
  given that you have an open transaction, you can send a rollback request.
  The server will rollback the transaction. Any further statements trying to run
  in this transaction will fail immediately.
  """
  @spec rollback(transaction) :: Transaction.result
  defdelegate rollback(conn), to: Transaction

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

  # defp defaults(opts) do
  #   Keyword.put_new(opts, :timeout, @timeout)
  # end

  defp pool_config(cnf) do
    [
      name: {:local, pool_name()},
      pool: Keyword.get(cnf, :pool),
      pool_size: Keyword.get(cnf, :pool_size),
      pool_overflow: Keyword.get(cnf, :max_overflow)
    ]
  end
end
