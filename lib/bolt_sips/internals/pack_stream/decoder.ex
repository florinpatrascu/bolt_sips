defmodule Bolt.Sips.Internals.PackStream.Decoder do
  @moduledoc false
  _moduledoc = """
  This module is responsible for dispatching decoding amongst decoder depending on the
  used bolt version.

  Most of the documentation regarding Bolt binary format can be found in
  `Bolt.Sips.Internals.PackStream.EncoderV1` and `Bolt.Sips.Internals.PackStream.EncoderV2`.

  Here will be found ocumenation about data that are only availalbe for decoding::
  - Node
  - Relationship
  - Unbound relationship
  - Path
  """

  use Bolt.Sips.Internals.PackStream.DecoderImplV1
  use Bolt.Sips.Internals.PackStream.DecoderImplV2
  use Bolt.Sips.Internals.PackStream.DecoderUtils
end
