defmodule Bolt.Sips.Internals.BoltProtocolHelper do
  @moduledoc false

  alias Bolt.Sips.Internals.PackStream.Message
  alias Bolt.Sips.Internals.Error

  @recv_timeout 10_000
  @zero_chunk <<0x00, 0x00>>
  @summary ~w(success ignored failure)a

  @doc """
  Sends a message using the Bolt protocol and PackStream encoding.

  Message have to be in the form of {message_type, [data]}.
  """
  @spec send_message(atom(), port(), integer(), Bolt.Sips.Internals.PackStream.Message.raw()) ::
          :ok | {:error, any()}
  def send_message(transport, port, bolt_version, message) do
    message
    |> Message.encode(bolt_version)
    |> (fn data -> transport.send(port, data) end).()
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

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec receive_data(atom(), port(), integer(), Keyword.t(), list()) ::
          {atom(), Bolt.Sips.Internals.PackStream.value()}
          | {:error, any()}
          | Bolt.Sips.Internals.Error.t()
  def receive_data(transport, port, bolt_version, options \\ [], previous \\ []) do
    with {:ok, data} <- do_receive_data(transport, port, options) do
      case Message.decode(data, bolt_version) do
        {:record, _} = data ->
          receive_data(transport, port, bolt_version, options, [data | previous])

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
          {:ok, <<old_data::binary, data::binary>>}

        <<chunk_size::16>> ->
          data = <<old_data::binary, data::binary>> 
          do_receive_data_(transport, port, chunk_size, options, data)
      end
    else
      other ->
        Error.exception(other, port, :recv)
    end
  end

  @doc """
  Define timeout
  """
  @spec get_recv_timeout(Keyword.t()) :: integer()
  def get_recv_timeout(options) do
    Keyword.get(options, :recv_timeout, @recv_timeout)
  end

  @doc """
  Deal with message without data.

  ## Example

      iex> BoltProtocolHelper.treat_simple_message(:reset, :gen_tcp, port, 1, [])
      :ok
  """
  @spec treat_simple_message(
          Bolt.Sips.Internals.Message.out_signature(),
          atom(),
          port(),
          integer(),
          Keyword.t()
        ) :: :ok | Error.t()
  def treat_simple_message(message, transport, port, bolt_version, options) do
    send_message(transport, port, bolt_version, {message, []})

    case receive_data(transport, port, bolt_version, options) do
      {:success, %{}} ->
        :ok

      error ->
        Error.exception(error, port, message)
    end
  end
end
