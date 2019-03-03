defmodule Bolt.Sips.Protocol do
  @moduledoc """
  Implements callbacks required by DBConnection.

  Each callback receives an open connection as a state.
  """

  use DBConnection
  use Retry

  require Logger

  alias Bolt.Sips
  alias Bolt.Sips.QueryStatement
  alias Bolt.Sips.Internals.Error, as: BoltError
  alias Bolt.Sips.Internals.BoltProtocol

  @doc "Callback for DBConnection.connect/1"
  def connect(_opts) do
    host = to_charlist(Sips.config(:hostname))
    port = Sips.config(:port)
    auth = extract_auth(Sips.config(:basic_auth))

    timeout = Sips.config(:timeout)

    socket_opts = [packet: :raw, mode: :binary, active: false]

    with {:ok, sock} <- socket().connect(host, port, socket_opts, timeout),
         :ok <- BoltProtocol.handshake(socket(), sock),
         {:ok, _version} <- BoltProtocol.init(socket(), sock, auth),
         :ok <- socket().setopts(sock, active: :once) do
      {:ok, sock}
    else
      {:error, %BoltError{}} = error ->
        error

      {:error, reason} ->
        {:error, BoltError.exception(reason, nil, :connect)}
    end
  end

  @doc "Callback for DBConnection.checkout/1"
  def checkout(sock) do
    case socket().setopts(sock, active: false) do
      :ok -> {:ok, sock}
      other -> other
    end
  end

  @doc "Callback for DBConnection.checkin/1"
  def checkin(sock) do
    case socket().setopts(sock, active: :once) do
      :ok -> {:ok, sock}
      other -> other
    end
  end

  @doc "Callback for DBConnection.disconnect/1"
  def disconnect(_err, sock) do
    socket().close(sock)

    :ok
  end

  @doc "Callback for DBConnection.handle_begin/1"
  def handle_begin(_opts, sock) do
    q = %QueryStatement{statement: "BEGIN"}

    handle_execute(q, %{}, [], sock)

    {:ok, :began, sock}
  end

  @doc "Callback for DBConnection.handle_rollback/1"
  def handle_rollback(_opts, sock) do
    q = %QueryStatement{statement: "ROLLBACK"}
    handle_execute(q, %{}, [], sock)
    {:ok, :rolledback, sock}
  end

  @doc "Callback for DBConnection.handle_commit/1"
  def handle_commit(_opts, sock) do
    q = %QueryStatement{statement: "COMMIT"}
    handle_execute(q, %{}, [], sock)
    {:ok, :committed, sock}
  end

  @doc "Callback for DBConnection.handle_execute/1"
  def handle_execute(query, params, opts, sock) do
    # only try to reconnect if the error is about the broken connection
    with {:disconnect, _, _} <- execute(query, params, opts, sock) do
      [
        delay: delay,
        factor: factor,
        tries: tries
      ] = Sips.config(:retry_linear_backoff)

      delay_stream =
        delay
        |> lin_backoff(factor)
        |> cap(Sips.config(:timeout))
        |> Stream.take(tries)

      retry with: delay_stream do
        with {:ok, sock} <- connect([]),
             {:ok, sock} <- checkout(sock) do
          execute(query, params, opts, sock)
        end
      end
    end
  end

  def handle_info(msg, state) do
    Logger.error(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received unexpected message: " | inspect(msg)]
    end)

    {:ok, state}
  end

  ### Calming the warnings
  # Callbacks for ...
  def ping(state), do: {:ok, state}
  def handle_prepare(query, _opts, state), do: {:ok, query, state}
  def handle_close(query, _opts, state), do: {:ok, query, state}
  def handle_deallocate(query, _cursor, _opts, state), do: {:ok, query, state}
  def handle_declare(query, _params, _opts, state), do: {:ok, query, state, nil}
  def handle_fetch(query, _cursor, _opts, state), do: {:cont, query, state}
  def handle_status(_opts, state), do: {:idle, state}

  defp extract_auth(nil), do: {}

  defp extract_auth(basic_auth), do: {basic_auth[:username], basic_auth[:password]}

  defp socket, do: Sips.config(:socket)

  defp execute(%QueryStatement{statement: statement} = q, params, _, sock) do
    case BoltProtocol.run_statement(socket(), sock, statement, params) do
      [{:success, _} | _] = data ->
        {:ok, q, data, sock}

      %BoltError{type: :cypher_error} = error ->
        with :ok <- BoltProtocol.ack_failure(socket(), sock) do
          {:error, error, sock}
        else
          error ->
            # we cannot handle this failure, so disconnect
            {:disconnect, error, sock}
        end

      %BoltError{type: :connection_error} = error ->
        {:disconnect, error, sock}

      %BoltError{} = error ->
        {:error, error, sock}
    end
  rescue
    e ->
      msg =
        case e do
          %Bolt.Sips.Internals.PackStream.EncodeError{} ->
            "unable to encode value: #{inspect(e.item)}"

          %BoltError{} ->
            "#{e.message}, type: #{e.type}"

          _ ->
            e.message
        end

      {:error, %{code: :failure, message: msg}, sock}
  end
end
