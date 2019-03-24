defmodule Bolt.Sips.Internals.PackStream.Message.Encoder do
  @moduledoc false
  _module_doc = """
  Manages the message encoding.

  A mesage is a tuple formated as:
  `{message_type, data}`
  with:
  - message_type: atom amongst the valid message type (:init, :discard_all, :pull_all,
  :ack_failure, :reset, :run)
  - data: a list of data to be used by the message

  Messages are passed in one or more chunk. The structure of a chunk is as follow: `chunk_size` `data`
  with `chunk_size` beign a 16-bit integer.
  A message always ends with the end marker `0x00 0x00`.
  Thus the possible typologies of messages are:
  - One-chunk message:
  `chunk_size` `message_data` `end_marker`
  - multiple-chunk message:
  `chunk_1_size` `message_data` `chunk_n_size` `message_data`...`end_marker`
  More documentation on message transfer encoding:
  [https://boltprotocol.org/v1/#message_transfer_encoding](https://boltprotocol.org/v1/#message_transfer_encoding)

  All messages are serialized structures. See `Bolt.Sips.Internals.PackStream.EncoderV1` for
  more information about structure encoding).

  An extensive documentation on messages can be found here:
  [https://boltprotocol.org/v1/#messages](https://boltprotocol.org/v1/#messages)
  """

  alias Bolt.Sips.Internals.BoltVersionHelper
  alias Bolt.Sips.Internals.PackStreamError

  @max_chunk_size 65_535
  @end_marker <<0x00, 0x00>>

  @available_bolt_versions BoltVersionHelper.available_versions()

  @doc """
  Return the valid message signatures depending on the Bolt version
  """
  @spec valid_signatures() :: [integer()]
  def valid_signatures() do
    Bolt.Sips.Internals.PackStream.Message.EncoderV1.valid_signatures()
  end

  @doc """
  Check if the encoder for the given bolt version is capable of encoding the given message
  If it is the case, the encoding function will be called
  If not, fallback to previous bolt version

  If encoding function is not present in any of the bolt  version, an error will be raised
  """
  @spec encode({atom(), list()}, integer()) :: binary() | Bolt.Sips.Internals.PackStreamError.t()
  def encode(data, bolt_version)
      when is_integer(bolt_version) and bolt_version in @available_bolt_versions do
    call_encode(data, bolt_version, bolt_version)
  end

  def encode(data, bolt_version) when is_integer(bolt_version) do
    if bolt_version > BoltVersionHelper.last() do
      encode(data, BoltVersionHelper.last())
    else
      raise PackStreamError,
        data: data,
        bolt_version: bolt_version,
        message: "[Message] Unsupported encoder version"
    end
  end

  def encode(data, bolt_version) do
    raise PackStreamError,
      data: data,
      bolt_version: bolt_version,
      message: "[Message] Unsupported encoder version"
  end

  defp call_encode(data, bolt_version, nil) do
    raise(PackStreamError,
      data: data,
      bolt_version: bolt_version,
      message: "[Message] Encoder not implemented for"
    )
  end

  defp call_encode(data, original_version, used_version) do
    module = Module.concat(["Bolt.Sips.Internals.PackStream.Message", "EncoderV#{used_version}"])

    with true <- Code.ensure_loaded?(module),
         true <- Kernel.function_exported?(module, :encode, 2),
         result <- Kernel.apply(module, :encode, [data, original_version]),
         true <- is_binary(result) do
      result
    else
      _ -> call_encode(data, original_version, BoltVersionHelper.previous(used_version))
    end
  end

  @doc """
  Perform the final message:
  - add header
  - manage chunk if necessary
  - add end marker
  """
  @spec encode_message(
          Bolt.Sips.Internals.PackStream.Message.out_signature(),
          integer(),
          list(),
          integer()
        ) ::
          Bolt.Sips.Internals.PackStream.Message.encoded()
  def encode_message(message_type, signature, data, bolt_version) do
    Bolt.Sips.Internals.Logger.log_message(:client, message_type, data)

    encoded =
      {signature, data}
      |> Bolt.Sips.Internals.PackStream.encode(bolt_version)
      |> generate_chunks()

    Bolt.Sips.Internals.Logger.log_message(:client, message_type, encoded, :hex)
    encoded
  end

  @spec generate_chunks(Bolt.Sips.Internals.PackStream.value() | <<>>, list()) ::
          Bolt.Sips.Internals.PackStream.Message.encoded()
  defp generate_chunks(data, chunks \\ [])

  defp generate_chunks(data, chunks) when byte_size(data) > @max_chunk_size do
    <<chunk::binary-@max_chunk_size, rest::binary>> = data
    generate_chunks(rest, [format_chunk(chunk) | chunks])
  end

  defp generate_chunks(<<>>, chunks) do
    [@end_marker | chunks]
    |> Enum.reverse()
    |> Enum.join()
  end

  defp generate_chunks(data, chunks) do
    generate_chunks(<<>>, [format_chunk(data) | chunks])
  end

  @spec format_chunk(Bolt.Sips.Internals.PackStream.value()) ::
          Bolt.Sips.Internals.PackStream.Message.encoded()
  defp format_chunk(chunk) do
    <<byte_size(chunk)::16>> <> chunk
  end
end
