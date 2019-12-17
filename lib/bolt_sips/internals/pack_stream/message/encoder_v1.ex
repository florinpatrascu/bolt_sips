defmodule Bolt.Sips.Internals.PackStream.Message.EncoderV1 do
  @moduledoc false
  use Bolt.Sips.Internals.PackStream.Message.Signatures
  alias Bolt.Sips.Internals.PackStream.Message.Encoder


  @doc """
  Encode INIT message without auth token
  """
  @spec encode({Bolt.Sips.Internals.PackStream.Message.out_signature(), list()}, integer()) ::
          Bolt.Sips.Internals.PackStream.Message.encoded() | {:error, :not_implemented}
  def encode(data, bolt_version) do
    Encoder.encode(data, bolt_version)
  end
end
