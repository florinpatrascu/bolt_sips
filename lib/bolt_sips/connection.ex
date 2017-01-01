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

  use Retry
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
        # future?: token = Base.encode64("#{username}:#{password}")
      else
        nil
      end

    # Doubles the delay with each retry, starting with 150 milliseconds,
    # cap the delay at `Bolt.Sips.config(:timeout)` second(s) and give up after 3 tries.
    [delay: delay, factor: factor, tries: tries] = Bolt.Sips.config(:retry_linear_backoff)
    p = retry with: lin_backoff(delay, factor) |> cap(Bolt.Sips.config(:timeout)) |> Stream.take(tries) do
      {:ok, p} = Bolt.Sips.config(:socket).connect(host, port, [active: false, mode: :binary, packet: :raw])
      :ok      = Boltex.Bolt.handshake(Bolt.Sips.config(:socket), p)
      :ok      = Boltex.Bolt.init(Bolt.Sips.config(:socket), p, auth)
      p
    end

    {:reply, p, opts}
  end

  @doc false
  def handle_call(data, _from, opts) do
    {s, query, params} = data

    [delay: delay, factor: factor, tries: tries] = Bolt.Sips.config(:retry_linear_backoff)
    result =
      retry with: lin_backoff(delay, factor) |> cap(Bolt.Sips.config(:timeout)) |> Stream.take(tries) do
        Boltex.Bolt.run_statement(Bolt.Sips.config(:socket), s, query, params)
      end
      |> ack_failure(Bolt.Sips.config(:socket), s)

    log("cypher: #{inspect query} - params: #{inspect params} - bolt: #{inspect result}")

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
  def send(cn, query), do: send(cn, query, %{})
  # def send(conn, query, params), do: Boltex.Bolt.run_statement(:gen_tcp, conn, query, params)
  def send(cn, query, params), do: pool_server(cn, query, params)

  defp pool_server(connection, query, params) do
    :poolboy.transaction(
      Bolt.Sips.pool_name,
      &(:gen_server.call(&1, {connection, query, params})), Bolt.Sips.config(:timeout)
    )
  end

  defp ack_failure(_response = {:failure, failure}, transport, port) do
    Boltex.Bolt.ack_failure(transport, port)
    {:failure, failure}
  end
  defp ack_failure(non_failure, _, _), do: non_failure

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
