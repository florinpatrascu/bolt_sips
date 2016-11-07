defmodule Boltex.Bolt do
  alias Boltex.{Utils, PackStream}
  require Logger

  @recv_timeout    1_000
  @max_chunk_size  65_535

  @user_agent      "Boltex/1.0"
  @hs_magic        << 0x60, 0x60, 0xB0, 0x17 >>
  @hs_version      << 1 :: 32, 0 :: 32, 0 :: 32, 0 :: 32 >>

  @zero_chunk      << 0, 0 >>

  @sig_init        0x01
  @sig_ack_failure 0x0E
  @sig_reset       0x0F
  @sig_run         0x10
  @sig_discard_all 0x2F
  @sig_pull_all    0x3F
  @sig_success     0x70
  @sig_record      0x71
  @sig_ignored     0x7E
  @sig_failure     0x7F

  @summary         ~w(success ignored failure)a

  @moduledoc """
  The Boltex.Bolt module handles the Bolt protocol specific steps (i.e.
  handshake, init) as well as sending and receiving messages and wrapping
  them in chunks.

  It abstracts transportation, expecing the transport layer to define
  send/2 and recv/3 analogous to :gen_tcp.
  """

  @doc "Does the handshake"
  def handshake(transport, port) do
    transport.send port, @hs_magic <> @hs_version
    case transport.recv(port, 4, @recv_timeout) do
      {:ok, << 1 :: 32 >>} ->
        :ok

      response ->
        Logger.error "Handshake failed. Received: #{Utils.hex_encode response})"
        {:error, :handshake_failed}
    end
  end

  @doc """
  Initialises the connection.

  Expects a transport module (i.e. `gen_tcp`) and a `Port`. Accepts
  authorisation params in the form of {username, password}.

  ## Examples

      iex> Boltex.Bolt.init :gen_tcp, port
      :ok

      iex> Boltex.Bolt.init :gen_tcp, port, {"username", "password"}
      :ok
  """
  def init(transport, port, auth \\ nil) do
    params = auth_params auth
    send_messages transport, port, [{[@user_agent, params], @sig_init}]

    case receive_data(transport, port) do
      {:success, %{}} ->
        :ok

      response ->
        Logger.error "Init failed. Received: #{Utils.hex_encode response})"
        {:error, :init_failed}
    end
  end

  defp auth_params(nil), do: %{}
  defp auth_params({username, password}) do
    %{
      scheme: "basic",
      principal: username,
      credentials: password
    }
  end

  @doc """
  Sends a list of messages using the Bolt protocol and PackStream encoding.

  Messages have to be in the form of {[messages], signature}.
  """
  def send_messages(transport, port, messages) do
    messages
    |> Enum.map(&generate_binary_message/1)
    |> generate_chunks
    |> Enum.each(&(transport.send(port, &1)))
  end

  defp generate_binary_message({messages, signature}) do
    messages    = List.wrap messages
    struct_size = length messages

    << 0xB :: 4, struct_size :: 4, signature >> <>
    Utils.reduce_to_binary(messages, &PackStream.encode/1)
  end

  defp generate_chunks(messages, chunks \\ [], current_chunk \\ <<>>)
  defp generate_chunks([], chunks, current_chunk) do
    [current_chunk | chunks]
    |> Enum.reverse
  end
  defp generate_chunks([message | messages], chunks, current_chunk)
  when byte_size(current_chunk <> message) <= @max_chunk_size do
    message_size  = byte_size message
    current_chunk =
      current_chunk <>
      << message_size :: 16 >> <>
      message <>
      @zero_chunk

    generate_chunks messages, chunks, current_chunk
  end
  defp generate_chunks([chunk | chunks], chunks, current_chunk) do
    oversized_chunk = current_chunk <> chunk
    {first, rest}   = binary_part oversized_chunk, 0, @max_chunk_size
    first_size      = byte_size first
    rest_size       = byte_size rest
    current_chunk   = current_chunk <> << first_size :: 16 >> <> first
    new_chunk       = << rest_size :: 16 >> <> rest

    generate_chunks chunks, [current_chunk | chunks], new_chunk
  end

  @doc """
  Runs a statement (most likely Cypher statement) and returns a list of the
  records and a summary.

  Records are represented using PackStream's record data type. Their Elixir
  representation is a Keyword with the indexse `:sig` and `:fields`.

  ## Examples

      iex> Boltex.Bolt.run_statement("MATCH (n) RETURN n")
      [
        {:record, [sig: 1, fields: [1, "Exmaple", "Labels", %{"some_attribute" => "some_value"}]]},
        {:success, %{"type" => "r"}}
      ]
  """
  def run_statement(transport, port, statement, params \\ %{}) do
    send_messages transport, port, [
      {[statement, params], @sig_run},
      {[nil], @sig_pull_all}
    ]

    with {:success, %{}} = data <- receive_data(transport, port),
    do:  [data | transport |> receive_data(port) |> List.wrap]
  end

  @doc """
  Acknowdledge a server error.

  This function is supposed to be called after a failure response has been
  received from the server.
  """
  def ack_failure(transport, port) do
    send_messages transport, port, [
      {[nil], @sig_ack_failure}
    ]

    with {:ignored, []} <- receive_data(transport, port),
        {:success, %{}} <- receive_data(transport, port),
    do: :ok
  end

  @doc """
  Receives data.

  This function is supposed to be called after a request to the server has been
  made. It receives data chunks, mends them (if they were split between frames)
  and decodes them using PackStream.

  When just a single message is received (i.e. to acknowledge a command), this
  function returns a tuple with two items, the first being the signature and the
  second being the message(s) itself. If a list of messages is received it will
  return a list of the former.

  The same goes for the messages: If there was a single data point in a message
  said data point will be returned by itself. If there were multiple data
  points, the list will be returned.

  The signature is represented as one of the following:

  * `:success`
  * `:record`
  * `:ignored`
  * `:failure`
  """
  def receive_data(transport, port, previous \\ []) do
    case transport |> do_receive_data(port) |> unpack do
      {:record, _} = data ->
        receive_data transport, port, [data | previous]

      {status, _} = data when status in @summary and previous == [] ->
        data

      {status, _} = data when status in @summary ->
        Enum.reverse [data | previous]
    end
  end

  defp do_receive_data(transport, port) do
    with {:ok, <<chunk_size :: 16>>} <- transport.recv(port, 2, @recv_timeout),
    do:  do_receive_data(transport, port, chunk_size)
  end
  defp do_receive_data(transport, port, chunk_size) do
    with {:ok, data} <- transport.recv(port, chunk_size, @recv_timeout)
    do
      case transport.recv(port, 2, @recv_timeout) do
        {:ok, @zero_chunk} ->
          data
        {:ok, <<chunk_size :: 16>>} ->
          data <> do_receive_data(transport, port, chunk_size)
      end
    else
      {:error, :timeout} ->
        {:error, :no_more_data_received}
      other ->
        raise "receive failed"
    end
  end

  @doc """
  Unpacks (or in other words parses) a message.
  """
  def unpack(<< 0x0B :: 4, packages :: 4, status, message :: binary >>) do
    response = PackStream.decode(message)
    response = if packages == 1, do: List.first(response), else: response

    case status do
      @sig_success -> {:success, response}
      @sig_record  -> {:record,  response}
      @sig_ignored -> {:ignored, response}
      @sig_failure -> {:failure, response}
      other        -> raise "Couldn't decode #{Utils.hex_encode << other >>}"
    end
  end
end
