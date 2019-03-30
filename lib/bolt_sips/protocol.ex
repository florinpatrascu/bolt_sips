defmodule Bolt.Sips.Protocol do
  @moduledoc false
  # Implements callbacks required by DBConnection.
  # Each callback receives an open connection as a state.

  defmodule ConnData do
    @moduledoc false
    # Defines the state used by DbConnection implementation
    defstruct [:sock, :bolt_version]

    @type t :: %__MODULE__{
            sock: port(),
            bolt_version: integer()
          }
  end

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
         {:ok, bolt_version} <- BoltProtocol.handshake(socket(), sock),
         {:ok, _info} <- do_init(socket(), sock, bolt_version, auth),
         :ok <- socket().setopts(sock, active: :once) do
      {:ok, %ConnData{sock: sock, bolt_version: bolt_version}}
    else
      {:error, %BoltError{}} = error ->
        error

      {:error, reason} ->
        {:error, BoltError.exception(reason, nil, :connect)}
    end
  end

  defp do_init(transport, port, 3, auth) do
    BoltProtocol.hello(transport, port, 3, auth)
  end

  defp do_init(transport, port, bolt_version, auth) do
    BoltProtocol.init(transport, port, bolt_version, auth)
  end

  @doc "Callback for DBConnection.checkout/1"
  def checkout(%ConnData{sock: sock} = conn_data) do
    case socket().setopts(sock, active: false) do
      :ok -> {:ok, conn_data}
      other -> other
    end
  end

  @doc "Callback for DBConnection.checkin/1"
  def checkin(%ConnData{sock: sock} = conn_data) do
    case socket().setopts(sock, active: :once) do
      :ok -> {:ok, conn_data}
      other -> other
    end
  end

  def disconnect(_err, %ConnData{sock: sock, bolt_version: 3} = conn_data) do
    :ok = BoltProtocol.goodbye(socket(), sock, conn_data.bolt_version)
    socket().close(sock)

    :ok
  end

  @doc "Callback for DBConnection.disconnect/1"
  def disconnect(_err, %ConnData{sock: sock}) do
    socket().close(sock)

    :ok
  end

  @doc "Callback for DBConnection.handle_begin/1"
  def handle_begin(_, %ConnData{sock: sock, bolt_version: 3} = conn_data) do
    {:ok, _} = BoltProtocol.begin(socket(), sock, conn_data.bolt_version)
    {:ok, :began, conn_data}
  end

  def handle_begin(_opts, conn_data) do
    q = %QueryStatement{statement: "BEGIN"}

    handle_execute(q, %{}, [], conn_data)

    {:ok, :began, conn_data}
  end

  @doc "Callback for DBConnection.handle_rollback/1"
  def handle_rollback(_opts, %ConnData{sock: sock, bolt_version: 3} = conn_data) do
    :ok = BoltProtocol.rollback(socket(), sock, conn_data.bolt_version)
    {:ok, :rolledback, conn_data}
  end

  def handle_rollback(_opts, conn_data) do
    q = %QueryStatement{statement: "ROLLBACK"}
    handle_execute(q, %{}, [], conn_data)
    {:ok, :rolledback, conn_data}
  end

  @doc "Callback for DBConnection.handle_commit/1"
  def handle_commit(_opts, %ConnData{sock: sock, bolt_version: 3} = conn_data) do
    {:ok, _} = BoltProtocol.commit(socket(), sock, conn_data.bolt_version)
    {:ok, :committed, conn_data}
  end

  def handle_commit(_opts, conn_data) do
    q = %QueryStatement{statement: "COMMIT"}
    handle_execute(q, %{}, [], conn_data)
    {:ok, :committed, conn_data}
  end

  @doc "Callback for DBConnection.handle_execute/1"
  def handle_execute(query, params, opts, conn_data) do
    # only try to reconnect if the error is about the broken connection
    with {:disconnect, _, _} <- execute(query, params, opts, conn_data) do
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
        with {:ok, conn_data} <- connect([]),
             {:ok, conn_data} <- checkout(conn_data) do
          execute(query, params, opts, conn_data)
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

  defp execute(
         %QueryStatement{statement: statement} = q,
         params,
         _,
         %ConnData{sock: sock, bolt_version: bolt_version} = conn_data
       ) do
    case BoltProtocol.run_statement(socket(), sock, bolt_version, statement, params) do
      [{:success, _} | _] = data ->
        {:ok, q, data, conn_data}

      %BoltError{type: :cypher_error} = error ->
        with :ok <- BoltProtocol.reset(socket(), sock, bolt_version) do
          {:error, error, conn_data}
        else
          error ->
            # we cannot handle this failure, so disconnect
            {:disconnect, error, conn_data}
        end

      %BoltError{type: :connection_error} = error ->
        {:disconnect, error, conn_data}

      %BoltError{} = error ->
        {:error, error, conn_data}
    end
  rescue
    e ->
      msg =
        case e do
          %Bolt.Sips.Internals.PackStreamError{} ->
            "unable to encode value: #{inspect(e.data)}"

          %BoltError{} ->
            "#{e.message}, type: #{e.type}"

          _ ->
            e.message
        end

      {:error, %{code: :failure, message: msg}, conn_data}
  end
end
