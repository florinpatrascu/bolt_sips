defmodule Bolt.Sips.BoltProtocol.Message.LogonMessage do
  import Bolt.Sips.BoltProtocol.Message.Shared.AuthHelper

  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Internals.PackStream.Message.Decoder

  def encode(bolt_version, fields) when is_float(bolt_version) and bolt_version >= 3.0 do
    message = [get_auth_params(fields)]
    Encoder.do_encode(:logon, message, 3)
  end

  def encode(_, _) do
    {:error, %Bolt.Sips.Internals.Error{code: :unsupported_message_version, message: "HELLO message version not supported"}}
  end

  def decode(response_message) do
    case Decoder.decode(response_message, 3) do
      {:success, response} ->
        response
      {:failure, response} ->
        {:error, response}
    end
  end
end
