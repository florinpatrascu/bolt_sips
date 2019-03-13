alias Bolt.Sips.Internals.PackStream
alias Bolt.Sips.Internals.PackStream.EncoderHelper

defprotocol Bolt.Sips.Internals.PackStream.Encoder do
  @moduledoc false

  # Encodes an item to its binary PackStream Representation
  #
  # Implementation exists for following types:
  #   - Integer
  #   - Float
  #   - List
  #   - Map
  #   - Struct (defined in the Bolt protocol)
  @fallback_to_any true

  @doc """
  Encode entity into its Bolt binary represenation depending of the used bolt version
  """

  @spec encode(any(), integer()) :: binary()
  def encode(entity, bolt_version)
end

defimpl PackStream.Encoder, for: Atom do
  def encode(data, bolt_version), do: EncoderHelper.call_encode(:atom, data, bolt_version)
end

defimpl PackStream.Encoder, for: BitString do
  def encode(data, bolt_version), do: EncoderHelper.call_encode(:string, data, bolt_version)
end

defimpl PackStream.Encoder, for: Integer do
  def encode(data, bolt_version), do: EncoderHelper.call_encode(:integer, data, bolt_version)
end

defimpl PackStream.Encoder, for: Float do
  def encode(data, bolt_version), do: EncoderHelper.call_encode(:float, data, bolt_version)
end

defimpl PackStream.Encoder, for: List do
  def encode(data, bolt_version), do: EncoderHelper.call_encode(:list, data, bolt_version)
end

defimpl PackStream.Encoder, for: Map do
  def encode(data, bolt_version), do: EncoderHelper.call_encode(:map, data, bolt_version)
end

defimpl PackStream.Encoder, for: Any do
  @valid_signatures PackStream.Message.Encoder.valid_signatures()

  @spec encode({integer(), list()} | %{:__struct__ => String.t()}, integer()) ::
          Bolt.Sips.Internals.PackStream.value() | <<_::16, _::_*8>>
  def encode({signature, data}, bolt_version)
      when signature in @valid_signatures and is_list(data) do
    EncoderHelper.call_encode(:struct, {signature, data}, bolt_version)
  end

  # Elixir structs just need to be convertedd to map befoare being encoded
  def encode(%{__struct__: _} = data, bolt_version) do
    map = Map.from_struct(data)
    PackStream.Encoder.encode(map, bolt_version)
  end

  def encode(data, bolt_version) do
    raise Bolt.Sips.Internals.PackStreamError,
      message: "Unable to encode",
      data: data,
      bolt_version: bolt_version
  end
end
