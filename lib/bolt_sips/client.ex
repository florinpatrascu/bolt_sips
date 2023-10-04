defmodule Bolt.Sips.Client do
  @hs_magic <<0x60, 0x60, 0xB0, 0x17>>

  alias Bolt.Sips.BoltProtocol.Versions

  defstruct [:sock, :connection_id, :version]

  defmodule Config do
    @moduledoc false

    @default_timeout 5_000

    defstruct [
      :address,
      :port,
      :username,
      :password,
      :connect_timeout,
      :socket_options,
      :versions
    ]

    def new(opts) do
      address = Keyword.get(opts, :address, System.get_env("MYSQL_HOST"))
      address = String.to_charlist(address || "localhost")
      versions = latest_versions(opts)

      default_port = String.to_integer(System.get_env("BOLT_TCP_PORT") || "7687")
      port = Keyword.get(opts, :port, default_port)

      %__MODULE__{
        address: address,
        port: port,
        username: Keyword.get(opts, :username, System.get_env("USER")) || raise(":username is missing"),
        password: Keyword.get(opts, :password),
        connect_timeout: Keyword.get(opts, :connect_timeout, @default_timeout),
        socket_options:
          Keyword.merge([mode: :binary, packet: :raw, active: false], opts[:socket_options] || []),
        versions: versions
      }
    end

    def latest_versions(opts) do
      latest_versions = Versions.latest_versions()
      versions = Keyword.get(opts, :versions, latest_versions)
      ((versions |> Enum.into([])) ++ [0, 0, 0]) |> Enum.take(4) |> Enum.sort(&>=/2)
    end

  end

  def connect(%Config{} = config) do
    with {:ok, client} <- do_connect(config) do
      handshake(client, config)
    end
  end

  def connect(opts) when is_list(opts) do
    connect(Config.new(opts))
  end

  def do_connect(config) do
    %{
      address: address,
      port: port,
      socket_options: socket_options,
      connect_timeout: connect_timeout
    } = config

    buffer? = Keyword.has_key?(socket_options, :buffer)
    client = %__MODULE__{connection_id: nil, sock: nil, version: nil}
    case :gen_tcp.connect(address, port, socket_options, connect_timeout) do
      {:ok, sock} when buffer? ->
        {:ok, %{client | sock: {:gen_tcp, sock}}}

      {:ok, sock} ->
        {:ok, [sndbuf: sndbuf, recbuf: recbuf, buffer: buffer]} =
          :inet.getopts(sock, [:sndbuf, :recbuf, :buffer])

        buffer = buffer |> max(sndbuf) |> max(recbuf)
        :ok = :inet.setopts(sock, buffer: buffer)
        {:ok, %{client | sock: {:gen_tcp, sock}}}

      other ->
        other
    end
  end

  defp handshake(client, config) do
    case do_handshake(client, config) do
      {:ok, client} ->
        {:ok, client}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_handshake(client, config) do
    data = @hs_magic <> (config.versions |>  Enum.sort(&>=/2) |> Enum.reduce(<<>>, fn version, acc -> acc <> Versions.to_bytes(version) end))
    with :ok <- send_packet(client, data),
    encode_version <- recv_packets(client, config.connect_timeout),
    version <- decode_version(encode_version) do
      case version do
        0.0 -> {:error, %Bolt.Sips.Error{code: :version_negotiation_error}}
        _ -> {:ok, %{client | version: version}}
      end
    else
      _ ->
        {:error, "Could not negotiate the version"}
    end
  end

  defp decode_version(<<0, 0, minor::unsigned-integer, major::unsigned-integer>>) when is_integer(major) and is_integer(minor) do
    Float.round(major + minor / 10.0, 1)
  end

  def send_packet(client, payload) do
    send_data(client, payload)
  end

  def send_data(%{sock: {sock_mod, sock}}, data) do
    sock_mod.send(sock, data)
  end

  def recv_packets(client, timeout) do
    case recv_data(client, timeout) do
      {:ok, response} ->
        response
      {:error, _} = error ->
        error
    end
  end

  def recv_data(%{sock: {sock_mod, sock}}, timeout) do
    sock_mod.recv(sock, 0, timeout)
  end
end
