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

  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper
  alias Bolt.Sips.Internals.PackStreamError

  @available_bolt_versions BoltVersionHelper.available_versions()

  @spec decode(binary() | {integer(), binary(), integer()}, integer()) :: list()
  def decode(data, bolt_version)
      when is_integer(bolt_version) and bolt_version in @available_bolt_versions do
    call_decode(data, bolt_version, bolt_version)
  end

  def decode(data, bolt_version) when is_integer(bolt_version) do
    if bolt_version > BoltVersionHelper.last() do
      decode(data, BoltVersionHelper.last())
    else
      raise PackStreamError,
        data: data,
        bolt_version: bolt_version,
        message: "Unsupported decoder version"
    end
  end

  def decode(data, bolt_version) do
    raise PackStreamError,
      data: data,
      bolt_version: bolt_version,
      message: "Unsupported decoder version"
  end

  # Check if the decoder for the given bolt version is capable of decoding the given data
  # If it is the case, the decoding function will be called
  # If not, fallback to previous bolt version
  #
  # If decoding function is present in none of the bolt  version, an error will be raised
  @spec call_decode(binary() | {integer(), binary(), integer()}, integer(), nil | integer()) ::
          list() | PackStreamError.t()
  defp call_decode(data, bolt_version, nil) do
    raise PackStreamError,
      data: data,
      bolt_version: bolt_version,
      message: "Decoder not implemented for"
  end

  defp call_decode(data, original_version, used_version) do
    module = Module.concat(["Bolt.Sips.Internals.PackStream", "DecoderV#{used_version}"])

    with true <- Code.ensure_loaded?(module),
         true <- Kernel.function_exported?(module, :decode, 2),
         result <- Kernel.apply(module, :decode, [data, original_version]),
         true <- is_list(result) do
      result
    else
      _ -> call_decode(data, original_version, BoltVersionHelper.previous(used_version))
    end
  end

  @doc """
  Decodes a struct
  """
  @spec decode_struct(binary(), integer(), integer()) :: {list(), list()}
  def decode_struct(struct, struct_size, bolt_version) do
    struct
    |> decode(bolt_version)
    |> Enum.split(struct_size)
  end
end
