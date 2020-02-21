defmodule Bolt.Sips.Protocol do
  @moduledoc false
  # Implements callbacks required by DBConnection.
  # Each callback receives an open connection as a state.

  defmodule ConnData do
    @moduledoc false
    # Defines the state used by DbConnection implementation
    defstruct [:sock, :bolt_version, :configuration]

    @type t :: %__MODULE__{
            sock: port(),
            bolt_version: integer(),
            configuration: Keyword.t()
          }
  end

  use DBConnection

  require Logger

  alias Bolt.Sips.QueryStatement
  alias Bolt.Sips.Internals.Error, as: BoltError
  alias Bolt.Sips.Internals.BoltProtocol

  @doc "Callback for DBConnection.connect/1"

  def connect(opts \\ [])
  def connect([]), do: connect(Bolt.Sips.Utils.default_config())

  def connect(opts) do
    conf = opts |> Bolt.Sips.Utils.default_config()
    host = _to_hostname(conf[:hostname])
    port = conf[:port]
    auth = extract_auth(conf[:basic_auth])
    timeout = conf[:timeout]
    socket = conf[:socket]
    socket_opts = [packet: :raw, mode: :binary, active: false]

    with {:ok, sock} <- socket.connect(host, port, socket_opts, timeout),
         {:ok, bolt_version} <- BoltProtocol.handshake(socket, sock),
         {:ok, server_version} <- do_init(socket, sock, bolt_version, auth),
         :ok <- socket.setopts(sock, active: :once) do
      {:ok,
       %ConnData{
         sock: sock,
         bolt_version: bolt_version,
         configuration: Keyword.merge(conf, server_version: server_version)
       }}
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
  def checkout(%ConnData{sock: sock, configuration: conf} = conn_data) do
    case conf[:socket].setopts(sock, active: false) do
      :ok -> {:ok, conn_data}
      other -> other
    end
  end

  @doc "Callback for DBConnection.checkin/1"
  def checkin(%ConnData{sock: sock, configuration: conf} = conn_data) do
    case conf[:socket].setopts(sock, active: :once) do
      :ok -> {:ok, conn_data}
      other -> other
    end
  end

  def disconnect(_err, %ConnData{sock: sock, bolt_version: 3, configuration: conf} = conn_data) do
    socket = conf[:socket]
    :ok = BoltProtocol.goodbye(socket, sock, conn_data.bolt_version)
    socket.close(sock)

    :ok
  end

  @doc "Callback for DBConnection.disconnect/1"
  def disconnect(_err, %ConnData{sock: sock, configuration: conf}) do
    conf[:socket].close(sock)

    :ok
  end

  @doc "Callback for DBConnection.handle_begin/1"
  def handle_begin(_, %ConnData{sock: sock, bolt_version: 3, configuration: conf} = conn_data) do
    {:ok, _} = BoltProtocol.begin(conf[:socket], sock, conn_data.bolt_version)
    {:ok, :began, conn_data}
  end

  def handle_begin(_opts, conn_data) do
    %QueryStatement{statement: "BEGIN"}
    |> handle_execute(%{}, [], conn_data)

    {:ok, :began, conn_data}
  end

  @doc "Callback for DBConnection.handle_rollback/1"
  def handle_rollback(_, %ConnData{sock: sock, bolt_version: 3, configuration: conf} = conn_data) do
    :ok = BoltProtocol.rollback(conf[:socket], sock, conn_data.bolt_version)
    {:ok, :rolledback, conn_data}
  end

  def handle_rollback(_opts, conn_data) do
    %QueryStatement{statement: "ROLLBACK"}
    |> handle_execute(%{}, [], conn_data)

    {:ok, :rolledback, conn_data}
  end

  @doc "Callback for DBConnection.handle_commit/1"
  def handle_commit(_, %ConnData{sock: sock, bolt_version: 3, configuration: conf} = conn_data) do
    {:ok, _} = BoltProtocol.commit(conf[:socket], sock, conn_data.bolt_version)
    {:ok, :committed, conn_data}
  end

  def handle_commit(_opts, conn_data) do
    %QueryStatement{statement: "COMMIT"}
    |> handle_execute(%{}, [], conn_data)

    {:ok, :committed, conn_data}
  end

  @doc "Callback for DBConnection.handle_execute/1"
  def handle_execute(query, params, opts, conn_data) do
    execute(query, params, opts, conn_data)
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

  defp execute(q, params, _, conn_data) do
    %QueryStatement{statement: statement} = q
    %ConnData{sock: sock, bolt_version: bolt_version, configuration: conf} = conn_data
    socket = conf |> Keyword.get(:socket)

    case BoltProtocol.run_statement(socket, sock, bolt_version, statement, params) do
      [{:success, _} | _] = data ->
        {:ok, q, data, conn_data}

      %BoltError{type: :cypher_error} = error ->
        BoltProtocol.reset(socket, sock, bolt_version)
        {:error, error, conn_data}

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

  defp _to_hostname(hostname) when is_binary(hostname), do: String.to_charlist(hostname)
  defp _to_hostname(hostname) when is_list(hostname), do: hostname
  defp _to_hostname(hostname), do: hostname
end
