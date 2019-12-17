defmodule Bolt.Sips.Internals.PackStream.DecoderV1 do
  @moduledoc false
  _moduledoc = """
  Bolt V1 can decode:
  - Null
  - Boolean
  - Integer
  - Float
  - String
  - List
  - Map
  - Struct

  Functions from this module are not meant to be used directly.
  Use `Decoder.decode(data, bolt_version)` for all decoding purposes.
  """

  use Bolt.Sips.Internals.PackStream.Markers
  alias Bolt.Sips.Internals.PackStream.Decoder
  alias Bolt.Sips.Types

  @spec decode(binary() | {integer(), binary(), integer()}, integer()) ::
          list() | {:error, :not_implemented}
  def decode(data, bolt_version), do: Decoder.decode(data, bolt_version)
end
