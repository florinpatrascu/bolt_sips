defmodule Bolt.Sips.Internals.BoltProtocol do
  alias Bolt.Sips.Internals.Error
  alias Bolt.Sips.Internals.PackStream.Message
  require Logger

  @recv_timeout 10_000

  @hs_magic <<0x60, 0x60, 0xB0, 0x17>>

  @zero_chunk <<0x00, 0x00>>

  @max_version 2

  @summary ~w(success ignored failure)a

  @moduledoc false

  # A library that handles Bolt Protocol (v1 and v2).
  # Note that for now, only Neo4j implements Bolt v2.

  # It handles all the protocol specific steps (i.e.
  # handshake, init) as well as sending and receiving messages and wrapping
  # them in chunks.

  # It abstracts transportation, expecting the transport layer to define
  # `send/2` and `recv/3` analogous to `:gen_tcp`.

  # ## Logging configuration
  # Logging can be enable / disable via config files (e.g, `config/config.exs`).
  #   - `:log`: (bool) wether Bolt.Sips.Internals. should produce logs or not. Defaults to `false`
  #   - `:log_hex`: (bool) wether Bolt.Sips.Internals. should produce logs hexadecimal counterparts. While this may be interesting,
  #   note that all the hexadecimal data will be written and this can be very long, and thus can seriously impact performances. Defaults to `false`

  # For example, configuration to see the logs and their hexadecimal counterparts:
  # ```
  #   config :Bolt.Sips.Internals.,
  #     log: true,
  #     log_hex: true
  # ```

  # #### Examples of logging (without log_hex)

  #     iex> Bolt.Sips.Internals.test('localhost', 7687, "RETURN 1 as num", %{}, {"neo4j", "password"})
  #     C: HANDSHAKE ~ "<<0x60, 0x60, 0xB0, 0x17>> [2, 1, 0, 0]"
  #     S: HANDSHAKE ~ 2
  #     C: INIT ~ ["BoltSips/1.1.0.rc2", %{credentials: "password", principal: "neo4j", scheme: "basic"}]
  #     S: SUCCESS ~ %{"server" => "Neo4j/3.4.1"}
  #     C: RUN ~ ["RETURN 1 as num", %{}]
  #     S: SUCCESS ~ %{"fields" => ["num"], "result_available_after" => 1}
  #     C: PULL_ALL ~ []
  #     S: RECORD ~ [1]
  #     S: SUCCESS ~ %{"result_consumed_after" => 0, "type" => "r"}
  #     [
  #       success: %{"fields" => ["num"], "result_available_after" => 1},
  #       record: [1],
  #       success: %{"result_consumed_after" => 0, "type" => "r"}
  #     ]

  # #### Examples of logging (with log_hex)

  #     iex> Bolt.Sips.Internals.test('localhost', 7687, "RETURN 1 as num", %{}, {"neo4j", "password"})
  #     13:32:23.882 [debug] C: HANDSHAKE ~ "<<0x60, 0x60, 0xB0, 0x17>> [2, 1, 0, 0]"
  #     S: HANDSHAKE ~ <<0x0, 0x0, 0x0, 0x2>>
  #     S: HANDSHAKE ~ 2
  #     C: INIT ~ ["BoltSips/1.1.0.rc2", %{credentials: "password", principal: "neo4j", scheme: "basic"}]
  #     C: INIT ~ <<0x0, 0x42, 0xB2, 0x1, 0x8C, 0x42, 0x6F, 0x6C, 0x74, 0x65, 0x78, 0x2F, 0x30, 0x2E, 0x35, 0x2E, 0x30, 0xA3, 0x8B, 0x63, 0x72, 0x65, 0x64, 0x65, 0x6E, 0x74, 0x69, 0x61, 0x6C, 0x73, 0x88, 0x70, 0x61, 0x73, 0x73, 0x77, 0x6F, 0x72, 0x64, 0x89, 0x70, 0x72, 0x69, 0x6E, 0x63, 0x69, 0x70, 0x61, 0x6C, 0x85, 0x6E, 0x65, 0x6F, 0x34, 0x6A, 0x86, 0x73, 0x63, 0x68, 0x65, 0x6D, 0x65, 0x85, 0x62, 0x61, 0x73, 0x69, 0x63, 0x0, 0x0>>
  #     S: SUCCESS ~ <<0xA1, 0x86, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x8B, 0x4E, 0x65, 0x6F, 0x34, 0x6A, 0x2F, 0x33, 0x2E, 0x34, 0x2E, 0x31>>
  #     S: SUCCESS ~ %{"server" => "Neo4j/3.4.1"}
  #     C: RUN ~ ["RETURN 1 as num", %{}]
  #     C: RUN ~ <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x31, 0x20, 0x61, 0x73, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0, 0x0>>
  #     S: SUCCESS ~ <<0xA2, 0xD0, 0x16, 0x72, 0x65, 0x73, 0x75, 0x6C, 0x74, 0x5F, 0x61, 0x76, 0x61, 0x69, 0x6C, 0x61, 0x62, 0x6C, 0x65, 0x5F, 0x61, 0x66, 0x74, 0x65, 0x72, 0x1, 0x86, 0x66, 0x69, 0x65, 0x6C, 0x64, 0x73, 0x91, 0x83, 0x6E, 0x75, 0x6D>>
  #     S: SUCCESS ~ %{"fields" => ["num"], "result_available_after" => 1}
  #     C: PULL_ALL ~ []
  #     C: PULL_ALL ~ <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>>
  #     S: RECORD ~ <<0x91, 0x1>>
  #     S: RECORD ~ [1]
  #     S: SUCCESS ~ <<0xA2, 0xD0, 0x15, 0x72, 0x65, 0x73, 0x75, 0x6C, 0x74, 0x5F, 0x63, 0x6F, 0x6E, 0x73, 0x75, 0x6D, 0x65, 0x64, 0x5F, 0x61, 0x66, 0x74, 0x65, 0x72, 0x0, 0x84, 0x74, 0x79, 0x70, 0x65, 0x81, 0x72>>
  #     S: SUCCESS ~ %{"result_consumed_after" => 0, "type" => "r"}
  #     [
  #       success: %{"fields" => ["num"], "result_available_after" => 1},
  #       record: [1],
  #       success: %{"result_consumed_after" => 0, "type" => "r"}
  #     ]

  # ## Shared options

  # Functions that allow for options accept these default options:

  #   * `recv_timeout`: The timeout for receiving a response from the Neo4J s
  #     server (default: #{@recv_timeout})

  @doc """
  Initiates the handshake between the client and the server.

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec handshake(atom(), port(), Keyword.t()) :: :ok | {:error, Bolt.Sips.Internals.Error.t()}
  def handshake(transport, port, options \\ []) do
    recv_timeout = get_recv_timeout(options)

    # Define version list. Should be a 4 integer list
    # Example: [1, 0, 0, 0]
    versions =
      ((@max_version..0
        |> Enum.into([])) ++ [0, 0, 0])
      |> Enum.take(4)

    Bolt.Sips.Internals.Logger.log_message(
      :client,
      :handshake,
      "#{inspect(@hs_magic, base: :hex)} #{inspect(versions)}"
    )

    data = @hs_magic <> Enum.into(versions, <<>>, fn version_ -> <<version_::32>> end)
    transport.send(port, data)

    case transport.recv(port, 4, recv_timeout) do
      {:ok, <<version::32>> = packet} when version <= @max_version ->
        Bolt.Sips.Internals.Logger.log_message(:server, :handshake, packet, :hex)
        Bolt.Sips.Internals.Logger.log_message(:server, :handshake, version)
        :ok

      {:ok, other} ->
        {:error, Error.exception(other, port, :handshake)}

      other ->
        {:error, Error.exception(other, port, :handshake)}
    end
  end

  @doc """
  Initialises the connection.

  Expects a transport module (i.e. `gen_tcp`) and a `Port`. Accepts
  authorisation params in the form of {username, password}.

  ## Options

  See "Shared options" in the documentation of this module.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocol.init :gen_tcp, port
      {:ok, info}

      iex> Bolt.Sips.Internals.BoltProtocol.init :gen_tcp, port, {"username", "password"}
      {:ok, info}
  """
  @spec init(atom(), port(), tuple(), Keyword.t()) ::
          {:ok, any()} | {:error, Bolt.Sips.Internals.Error.t()}
  def init(transport, port, auth \\ {}, options \\ []) do
    send_message(transport, port, {:init, [auth]})

    case receive_data(transport, port, options) do
      {:success, info} ->
        {:ok, info}

      {:failure, response} ->
        {:error, Error.exception(response, port, :init)}

      other ->
        {:error, Error.exception(other, port, :init)}
    end
  end

  @doc false
  # Sends a message using the Bolt protocol and PackStream encoding.
  #
  # Message have to be in the form of {message_type, [data]}.
  @spec send_message(atom(), port(), Bolt.Sips.Internals.PackStream.Message.raw()) ::
          :ok | {:error, any()}
  def send_message(transport, port, message) do
    message
    |> Message.encode()
    |> (fn data -> transport.send(port, data) end).()
  end

  @doc """
  Runs a statement (most likely Cypher statement) and returns a list of the
  records and a summary (Act as as a RUN + PULL_ALL).

  Records are represented using PackStream's record data type. Their Elixir
  representation is a Keyword with the indexes `:sig` and `:fields`.

  ## Options

  See "Shared options" in the documentation of this module.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocol.run_statement("MATCH (n) RETURN n")
      [
        {:success, %{"fields" => ["n"]}},
        {:record, [sig: 1, fields: [1, "Example", "Labels", %{"some_attribute" => "some_value"}]]},
        {:success, %{"type" => "r"}}
      ]
  """
  @spec run_statement(atom(), port(), String.t(), map(), Keyword.t()) ::
          [
            Bolt.Sips.Internals.PackStream.Message.decoded()
          ]
          | Bolt.Sips.Internals.Error.t()
  def run_statement(transport, port, statement, params \\ %{}, options \\ []) do
    data = [statement, params]

    with :ok <- send_message(transport, port, {:run, data}),
         {:success, _} = data <- receive_data(transport, port, options),
         :ok <- send_message(transport, port, {:pull_all, []}),
         more_data <- receive_data(transport, port, options),
         more_data = List.wrap(more_data),
         {:success, _} <- List.last(more_data) do
      [data | more_data]
    else
      {:failure, map} ->
        Bolt.Sips.Internals.Error.exception(map, port, :run_statement)

      error = %Error{} ->
        error

      error ->
        Error.exception(error, port, :run_statement)
    end
  end

  @doc """
  Implementation of Bolt's ACK_FAILURE. It acknowledges a failure while keeping
  transactions alive.

  See http://boltprotocol.org/v1/#message-ack-failure

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec ack_failure(atom(), port(), Keyword.t()) :: :ok | Bolt.Sips.Internals.Error.t()
  def ack_failure(transport, port, options \\ []) do
    send_message(transport, port, {:ack_failure, []})

    case receive_data(transport, port, options) do
      {:success, %{}} -> :ok
      error -> Error.exception(error, port, :ack_failure)
    end
  end

  @doc """
  Implementation of Bolt's RESET message. It resets a session to a "clean"
  state.

  See http://boltprotocol.org/v1/#message-reset

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec reset(atom(), port(), Keyword.t()) :: :ok | Bolt.Sips.Internals.Error.t()
  def reset(transport, port, options \\ []) do
    send_message(transport, port, {:reset, []})

    case receive_data(transport, port, options) do
      {:success, %{}} -> :ok
      error -> Error.exception(error, port, :reset)
    end
  end

  @doc false
  # Receives data.
  #
  # This function is supposed to be called after a request to the server has been
  # made. It receives data chunks, mends them (if they were split between frames)
  # and decodes them using PackStream.
  #
  # When just a single message is received (i.e. to acknowledge a command), this
  # function returns a tuple with two items, the first being the signature and the
  # second being the message(s) itself. If a list of messages is received it will
  # return a list of the former.
  #
  # The same goes for the messages: If there was a single data point in a message
  # said data point will be returned by itself. If there were multiple data
  # points, the list will be returned.
  #
  # The signature is represented as one of the following:
  #
  # * `:success`
  # * `:record`
  # * `:ignored`
  # * `:failure`
  #
  # ## Options
  #
  # See "Shared options" in the documentation of this module.
  @spec receive_data(atom(), port(), Keyword.t(), list()) ::
          {atom(), Bolt.Sips.Internals.PackStream.value()} | {:error, any()}
  def receive_data(transport, port, options \\ [], previous \\ []) do
    with {:ok, data} <- do_receive_data(transport, port, options) do
      case Message.decode(data) do
        {:record, _} = data ->
          receive_data(transport, port, options, [data | previous])

        {status, _} = data when status in @summary and previous == [] ->
          data

        {status, _} = data when status in @summary ->
          Enum.reverse([data | previous])

        other ->
          {:error, Error.exception(other, port, :receive_data)}
      end
    else
      other ->
        # Should be the line below to have a cleaner typespec
        # Keep the old return value to not break usage
        # {:error, Error.exception(other, port, :receive_data)}
        Error.exception(other, port, :receive_data)
    end
  end

  @spec do_receive_data(atom(), port(), Keyword.t()) :: {:ok, binary()}
  defp do_receive_data(transport, port, options) do
    recv_timeout = get_recv_timeout(options)

    case transport.recv(port, 2, recv_timeout) do
      {:ok, <<chunk_size::16>>} ->
        do_receive_data_(transport, port, chunk_size, options, <<>>)

      other ->
        other
    end
  end

  @spec do_receive_data_(atom(), port(), integer(), Keyword.t(), binary()) :: {:ok, binary()}
  defp do_receive_data_(transport, port, chunk_size, options, old_data) do
    recv_timeout = get_recv_timeout(options)

    with {:ok, data} <- transport.recv(port, chunk_size, recv_timeout),
         {:ok, marker} <- transport.recv(port, 2, recv_timeout) do
      case marker do
        @zero_chunk ->
          {:ok, old_data <> data}

        <<chunk_size::16>> ->
          data = old_data <> data
          do_receive_data_(transport, port, chunk_size, options, data)
      end
    else
      other ->
        Error.exception(other, port, :recv)
    end
  end

  @spec get_recv_timeout(Keyword.t()) :: integer()
  defp get_recv_timeout(options) do
    Keyword.get(options, :recv_timeout, @recv_timeout)
  end
end
