defmodule Bolt.Sips.Connection do
  @moduledoc """
  This module handles the connection to Neo4j, providing support
  for queries, transactions, logging, pooling and more.

  Do not use this module directly. Use the `Bolt.Sips.conn` instead
  """
  defstruct [:opts]

  @type t :: %__MODULE__{opts: Keyword.t}
  @type conn :: GenServer.server | t

  use GenServer

  import Kernel, except: [send: 2]

  require Logger

  @doc false
  def start_link(opts) do
    # IO.puts(inspect(__MODULE__ ) <> " start_link: #{inspect opts}")
    GenServer.start_link(__MODULE__, opts, [])
  end

  @doc false
  def handle_call(:connect, _from, opts) do
    # IO.puts(inspect(__MODULE__ ) <> " handle_call: :connect, from: #{inspect from}, opts: #{inspect opts}")

    host       = Keyword.fetch!(opts, :hostname) |> to_char_list
    port       = opts[:port]
    auth =
      if basic_auth = opts[:basic_auth] do
        {basic_auth[:username], basic_auth[:password]}
        # todo: token = Base.encode64("#{username}:#{password}")
      else
        nil
      end
    # timeout    = opts[:timeout]

    {:ok, p} = :gen_tcp.connect(host, port, [active: false, mode: :binary, packet: :raw])
    :ok        = Boltex.Bolt.handshake(:gen_tcp, p)
    :ok        = Boltex.Bolt.init(:gen_tcp, p, auth)

    # todo: add error support
    {:reply, p, opts}
  end

  @doc false
  def handle_call(data, _from, opts) do
    # IO.puts(inspect(__MODULE__ )<> " handle_call: #{inspect data}, opts: #{inspect opts}")
    {s, query, params} = data
    result = Boltex.Bolt.run_statement(:gen_tcp, s, query, params)
    log("#{inspect s} - cypher: #{inspect query} - params: #{inspect params} - bolt: #{inspect result}")

    # :random.seed(:os.timestamp)
    # timeout = opts[:timeout] || 5000
    {:reply, result, opts}
  end

  def conn() do
    :poolboy.transaction(
       Bolt.Sips.pool_name, &(:gen_server.call(&1, :connect)),
       Bolt.Sips.config(:timeout)
    )
  end

  @doc false
  def send(conn, query), do: send(conn, query, %{})
  # def send(conn, query, params), do: Boltex.Bolt.run_statement(:gen_tcp, conn, query, params)
  def send(conn, query, params), do: pool_server(conn, query, params)

  defp pool_server(connection, query, params) do
    :poolboy.transaction(
      Bolt.Sips.pool_name,
      &(:gen_server.call(&1, {connection, query, params})), Bolt.Sips.config(:timeout)
    )
  end

   @doc false
   def terminate(_reason, _state) do
     :ok
   end

   def init(state) do
     {:ok, state}
   end

  @doc """
  Logs the given message in debug mode.

  The logger call will be removed at compile time if `compile_time_purge_level`
  is set to higher than :debug
  """
  def log(message) when is_binary(message) do
    Logger.debug(message)
  end
end
