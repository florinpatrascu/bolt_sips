defmodule Bolt.Sips.Internals.PackStream.Message do
  @moduledoc false

  # Manage the message encoding and decoding.
  #
  # Message encoding / decoding is the first step of encoding / decoding.
  # The next step is the message data encoding /decoding (which is handled by packstream.ex)

  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Internals.PackStream.Message.Decoder

  @type in_signature :: :failure | :ignored | :record | :success
  @type out_signature :: :init | :run | :ack_failure | :discard_all | :pull_all | :reset
  @type raw :: {out_signature, list()}
  @type decoded :: {in_signature(), any()}
  @type encoded :: <<_::16, _::_*8>>

  @doc """
  Encode a message depending on its type
  """
  @spec encode({Bolt.Sips.Internals.PackStream.Message.out_signature(), list()}) ::
          Bolt.Sips.Internals.PackStream.Message.encoded()
  def encode(message) do
    Encoder.encode(message)
  end

  @doc """
  Decode a message
  """
  @spec decode(Bolt.Sips.Internals.PackStream.Message.encoded()) ::
          Bolt.Sips.Internals.PackStream.Message.decoded()
  def decode(message) do
    Decoder.decode(message)
  end
end
