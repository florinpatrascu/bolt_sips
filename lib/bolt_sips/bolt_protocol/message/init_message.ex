defmodule Bolt.Sips.BoltProtocol.Message.InitMessage do
  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Internals.PackStream.Message.Decoder

  def encode(bolt_version, fields) when is_float(bolt_version) and bolt_version >= 1.0 do
    message = [get_user_agent(fields), get_auth_params(fields)]
    Encoder.do_encode(:init, message, 1)
  end

  def encode(_, _) do
    {:error, %Bolt.Sips.Internals.Error{code: :unsupported_message_version, message: "Init message version not supported"}}
  end

  def decode(response_message) do
    case Decoder.decode(response_message, 1) do
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
    Keyword.get(fields, :user_agent, default_user_agent)
  end
end
