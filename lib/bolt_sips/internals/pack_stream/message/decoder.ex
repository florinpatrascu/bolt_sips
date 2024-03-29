defmodule Bolt.Sips.Internals.PackStream.Message.Decoder do
  @moduledoc false

  @tiny_struct_marker 0xB

  @success_signature 0x70
  @failure_signature 0x7F
  @record_signature 0x71
  @ignored_signature 0x7E

  # Decode SUCCESS message
  @spec decode(Bolt.Sips.Internals.PackStream.Message.encoded(), integer()) ::
          Bolt.Sips.Internals.PackStream.Message.decoded()
  def decode(
        <<@tiny_struct_marker::4, nb_entries::4, @success_signature, data::binary>>,
        bolt_version
      ) do
    build_response(:success, data, nb_entries, bolt_version)
  end

  # Decode FAILURE message
  def decode(
        <<@tiny_struct_marker::4, nb_entries::4, @failure_signature, data::binary>>,
        bolt_version
      ) do
    build_response(:failure, data, nb_entries, bolt_version)
  end

  # Decode RECORD message
  def decode(
        <<@tiny_struct_marker::4, nb_entries::4, @record_signature, data::binary>>,
        bolt_version
      ) do
    build_response(:record, data, nb_entries, bolt_version)
  end

  # Decode IGNORED message
  def decode(
        <<@tiny_struct_marker::4, nb_entries::4, @ignored_signature, data::binary>>,
        bolt_version
      ) do
    build_response(:ignored, data, nb_entries, bolt_version)
  end

  @spec build_response(
          Bolt.Sips.Internals.PackStream.Message.in_signature(),
          any(),
          integer(),
          integer()
        ) ::
          Bolt.Sips.Internals.PackStream.Message.decoded()
  defp build_response(message_type, data, nb_entries, bolt_version) do
    Bolt.Sips.Internals.Logger.log_message(:server, message_type, data, :hex)

    response =
      case Bolt.Sips.Internals.PackStream.decode(data, bolt_version) do
        response when nb_entries == 1 ->
          List.first(response)

        responses ->
          responses
      end

    Bolt.Sips.Internals.Logger.log_message(:server, message_type, response)
    {message_type, response}
  end
end
