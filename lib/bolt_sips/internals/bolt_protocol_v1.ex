defmodule Bolt.Sips.Internals.BoltProtocolV1 do
  @moduledoc false
  alias Bolt.Sips.Internals.BoltProtocolHelper
  alias Bolt.Sips.Internals.BoltVersionHelper
  alias Bolt.Sips.Internals.Error

  @hs_magic <<0x60, 0x60, 0xB0, 0x17>>

  @doc """
  Initiates the handshake between the client and the server.

  See [http://boltprotocol.org/v1/#handshake](http://boltprotocol.org/v1/#handshake)

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.handshake(:gen_tcp, port, [])
      {:ok, bolt_version}
  """
  @spec handshake(atom(), port(), Keyword.t()) ::
          {:ok, integer()} | {:error, Bolt.Sips.Internals.Error.t()}
  def handshake(transport, port, options) do
    recv_timeout = BoltProtocolHelper.get_recv_timeout(options)
    max_version = BoltVersionHelper.last()

    # Define version list. Should be a 4 integer list
    # Example: [1, 0, 0, 0]
    versions =
      ((max_version..0
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
      {:ok, <<version::32>> = packet} when version <= max_version ->
        Bolt.Sips.Internals.Logger.log_message(:server, :handshake, packet, :hex)
        Bolt.Sips.Internals.Logger.log_message(:server, :handshake, version)
        {:ok, version}

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

  See [https://boltprotocol.org/v1/#message-init](https://boltprotocol.org/v1/#message-init)

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocol.init(:gen_tcp, port, 1, {}, [])
      {:ok, info}

      iex> Bolt.Sips.Internals.BoltProtocol.init(:gen_tcp, port, 1, {"username", "password"}, [])
      {:ok, info}
  """
  @spec init(atom(), port(), integer(), tuple(), Keyword.t()) ::
          {:ok, any()} | {:error, Bolt.Sips.Internals.Error.t()}
  def init(transport, port, bolt_version, auth, options) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:init, [auth]})

    case BoltProtocolHelper.receive_data(transport, port, bolt_version, options) do
      {:success, info} ->
        {:ok, info}

      {:failure, response} ->
        {:error, Error.exception(response, port, :init)}

      other ->
        {:error, Error.exception(other, port, :init)}
    end
  end

  @doc """
  Implementation of Bolt's RUN. It passes a statement for execution on the server.

  Note that this message doesn't return the statemetn result. For this purpose, use PULL_ALL.

  See [https://boltprotocol.org/v1/#message-run](https://boltprotocol.org/v1/#message-run)

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN {num} AS num", %{num: 5}, [])
      {:ok, {:success, %{"fields" => ["num"]}}}
  """
  @spec run(atom(), port(), integer(), String.t(), map(), Keyword.t()) ::
          {:ok, any()} | {:error, Bolt.Sips.Internals.Error.t()}
  def run(transport, port, bolt_version, statement, params, options) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:run, [statement, params]})

    case BoltProtocolHelper.receive_data(transport, port, bolt_version, options) do
      {:success, _} = result ->
        {:ok, result}

      {:failure, response} ->
        {:error, Error.exception(response, port, :run)}

      %Error{} = error ->
        {:error, error}

      other ->
        {:error, Error.exception(other, port, :run)}
    end
  end

  @doc """
  Implementation of Bolt's PULL_ALL. It retrieves all remaining items from the active result
  stream.

  See [https://boltprotocol.org/v1/#message-run](https://boltprotocol.org/v1/#message-run)

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN {num} AS num", %{num: 5}, [])
      {:ok, {:success, %{"fields" => ["num"]}}}
      iex> BoltProtocolV1.pull_all(:gen_tcp, port_, 1, [])
      {:ok,
        [
          record: [5],
          success: %{"type" => "r"}
        ]}
  """
  @spec pull_all(atom(), port(), integer(), Keyword.t()) ::
          {:ok, list()}
          | {:failure, Bolt.Sips.Internals.Error.t()}
          | {:failure, Bolt.Sips.Internals.Error.t()}
  def pull_all(transport, port, bolt_version, options) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:pull_all, []})

    with data <- BoltProtocolHelper.receive_data(transport, port, bolt_version, options),
         data <- List.wrap(data),
         {:success, _} <- List.last(data) do
      {:ok, data}
    else
      {:failure, response} ->
        {:failure, Error.exception(response, port, :pull_all)}

      other ->
        {:error, Error.exception(other, port, :pull_all)}
    end
  end

  @doc """
  Runs a statement (most likely Cypher statement) and returns a list of the
  records and a summary (Act as as a RUN + PULL_ALL).

  Records are represented using PackStream's record data type. Their Elixir
  representation is a Keyword with the indexes `:sig` and `:fields`.

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocol.run_statement(:gen_tcp, port, 1, "MATCH (n) RETURN n")
      [
        {:success, %{"fields" => ["n"]}},
        {:record, [sig: 1, fields: [1, "Example", "Labels", %{"some_attribute" => "some_value"}]]},
        {:success, %{"type" => "r"}}
      ]
  """
  @spec run_statement(atom(), port(), integer(), String.t(), map(), Keyword.t()) ::
          [
            Bolt.Sips.Internals.PackStream.Message.decoded()
          ]
          | Bolt.Sips.Internals.Error.t()
  def run_statement(transport, port, bolt_version, statement, params, options) do
    with {:ok, run_data} <- run(transport, port, bolt_version, statement, params, options),
         {:ok, result} <- pull_all(transport, port, bolt_version, options) do
      [run_data | result]
    else
      {:error, %Error{} = error} ->
        error

      other ->
        Error.exception(other, port, :run_statement)
    end
  end

  @doc """
  Implementation of Bolt's DISCARD_ALL. It discards all remaining items from the active result
  stream.

  See [https://boltprotocol.org/v1/#message-discard-all](https://boltprotocol.org/v1/#message-discard-all)

  See http://boltprotocol.org/v1/#message-ack-failure

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.discard_all(:gen_tcp, port, 1, [])
      :ok
  """
  @spec discard_all(atom(), port(), integer(), Keyword.t()) :: :ok | Bolt.Sips.Internals.Error.t()
  def discard_all(transport, port, bolt_version, options) do
    BoltProtocolHelper.treat_simple_message(:discard_all, transport, port, bolt_version, options)
  end

  @doc """
  Implementation of Bolt's ACK_FAILURE. It acknowledges a failure while keeping
  transactions alive.

  See [http://boltprotocol.org/v1/#message-ack-failure](http://boltprotocol.org/v1/#message-ack-failure)

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.ack_failure(:gen_tcp, port, 1, [])
      :ok
  """
  @spec ack_failure(atom(), port(), integer(), Keyword.t()) :: :ok | Bolt.Sips.Internals.Error.t()
  def ack_failure(transport, port, bolt_version, options) do
    BoltProtocolHelper.treat_simple_message(:ack_failure, transport, port, bolt_version, options)
  end

  @doc """
  Implementation of Bolt's RESET message. It resets a session to a "clean"
  state.

  See [http://boltprotocol.org/v1/#message-reset](http://boltprotocol.org/v1/#message-reset)

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.reset(:gen_tcp, port, 1, [])
      :ok
  """
  @spec reset(atom(), port(), integer(), Keyword.t()) :: :ok | Bolt.Sips.Internals.Error.t()
  def reset(transport, port, bolt_version, options) do
    BoltProtocolHelper.treat_simple_message(:reset, transport, port, bolt_version, options)
  end
end
