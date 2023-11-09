defmodule Bolt.Sips.BoltProtocol.Message.HelloMessage do
  import Bolt.Sips.BoltProtocol.Message.Shared.AuthHelper

  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Internals.PackStream.Message.Decoder

  def encode(bolt_version, fields) when is_float(bolt_version) and bolt_version >= 5.1 do
    message = [Map.merge(get_user_agent(bolt_version, fields), get_bolt_agent(fields))]
    Encoder.do_encode(:hello, message, 3)
  end

  def encode(bolt_version, fields) when is_float(bolt_version) and bolt_version >= 3.0 do
    message = [Map.merge(get_auth_params(fields), get_user_agent(bolt_version, fields))]
    Encoder.do_encode(:hello, message, 3)
  end

  def encode(_, _) do
    {:error, %Bolt.Sips.Internals.Error{code: :unsupported_message_version, message: "HELLO message version not supported"}}
  end

  def decode(response_message) do
    case Decoder.decode(response_message, 3) do
      {:success, response} ->
        {:ok, response}
      {:failure, response} ->
        {:error, response}
    end
  end
end
