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
    GenServer.start_link(__MODULE__, opts, [])
  end

  @doc false
  def handle_call(:connect, _from, opts) do
    host  = Keyword.fetch!(opts, :hostname) |> to_charlist
    port  = opts[:port]
    auth  = opts[:auth]

    [delay: delay, factor: factor, tries: tries] = Bolt.Sips.config(:retry_linear_backoff)

    p = retry with: lin_backoff(delay, factor) |> cap(Bolt.Sips.config(:timeout)) |> Stream.take(tries) do
      case Bolt.Sips.config(:socket).connect(host, port, [active: false, mode: :binary, packet: :raw]) do
        {:ok, p} ->
          with :ok <- Boltex.Bolt.handshake(Bolt.Sips.config(:socket), p, boltex_opts()),
               :ok <- Boltex.Bolt.init(Bolt.Sips.config(:socket), p, auth, boltex_opts()),
               do: p
        _ -> :error
      end
    end

    case p do
      :error -> {:noreply, p, opts}
      _ -> {:reply, p, opts}
    end
  end

  @doc false
  def handle_call(data, _from, opts) do
    {s, query, params} = data

    [delay: delay, factor: factor, tries: tries] = Bolt.Sips.config(:retry_linear_backoff)
    result =
      retry with: lin_backoff(delay, factor) |> cap(Bolt.Sips.config(:timeout)) |> Stream.take(tries) do
        try do
          r =
            Boltex.Bolt.run_statement(Bolt.Sips.config(:socket), s, query, params, boltex_opts())
            |> ack_failure(Bolt.Sips.config(:socket), s)
            log("[#{inspect s}] cypher: #{inspect query} - params: #{inspect params} - bolt: #{inspect r}")
          r
        rescue e ->
          Boltex.Bolt.ack_failure(Bolt.Sips.config(:socket), s, boltex_opts())
          msg =
            case e do
              %Boltex.PackStream.EncodeError{} -> "unable to encode value: #{inspect e.item}"
              %Boltex.Error{} -> "#{e.message}, type: #{e.type}"
              _err -> e.message
            end
          log("[#{inspect s}] cypher: #{inspect query} - params: #{inspect params} - Error: '#{msg}'. Stacktrace: #{inspect System.stacktrace}")
          {:failure, %{"code" => :failure, "message" => msg}}
        end
      end

    {:reply, result, opts}
  end

  def conn() do
    :poolboy.transaction(
      Bolt.Sips.pool_name, &(:gen_server.call(&1, :connect, Bolt.Sips.config(:timeout))),
      :infinity
    )
  end

  @doc false
  def send(cn, query), do: send(cn, query, %{})
  # def send(conn, query, params), do: Boltex.Bolt.run_statement(:gen_tcp, conn, query, params)
  def send(cn, query, params), do: pool_server(cn, query, params)

  defp pool_server(connection, query, params) do
    :poolboy.transaction(
      Bolt.Sips.pool_name,
      &(:gen_server.call(&1, {connection, query, params}, Bolt.Sips.config(:timeout))),
      :infinity
    )
  end

  @doc false
  def terminate(_reason, _state) do
    :ok
  end

  def init(state) do
    auth =
      if basic_auth = state[:basic_auth] do
        {basic_auth[:username], basic_auth[:password]}
      else
        {}
      end

    {:ok, state |> Keyword.put(:auth, auth)}
  end


  @doc """
  Logs the given message in debug mode.

  The logger call will be removed at compile time if `compile_time_purge_level`
  is set to higher than :debug
  """
  def log(message) when is_binary(message) do
    Logger.debug(message)
  end


  defp ack_failure(%Boltex.Error{} = response, transport, port) do
    Boltex.Bolt.ack_failure(transport, port, boltex_opts())
    {:error, response}
  end
  defp ack_failure(non_failure, _, _), do: non_failure

  @doc false

  defp boltex_opts() do
    [recv_timeout: Bolt.Sips.config(:timeout)]
  end

end
