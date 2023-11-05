defmodule Bolt.Sips.BoltProtocol.Message.HelloMessage do
  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Internals.PackStream.Message.Decoder

  def encode(bolt_version, fields) when is_float(bolt_version) and bolt_version >= 3.0 do
    message = [Map.merge(get_auth_params(fields), get_user_agent(fields))]
    Encoder.do_encode(:hello, message, 3)
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

  defp get_auth_params(fields) do
    %{
      scheme: "basic",
      principal: fields[:auth][:username],
      credentials: fields[:auth][:password]
    }
  end

  defp get_user_agent(fields) do
    default_user_agent = "BoltSips/" <> to_string(Application.spec(:bolt_sips, :vsn))
    user_agent = Keyword.get(fields, :user_agent, default_user_agent)
    %{user_agent: user_agent}
  end
end
