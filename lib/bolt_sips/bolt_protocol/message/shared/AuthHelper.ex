defmodule Bolt.Sips.BoltProtocol.Message.Shared.AuthHelper do
  def get_auth_params(fields) do
    %{
      scheme: "basic",
      principal: fields[:auth][:username],
      credentials: fields[:auth][:password]
    }
  end

  def get_user_agent(fields) do
    default_user_agent = "BoltSips/" <> to_string(Application.spec(:bolt_sips, :vsn))
    Keyword.get(fields, :user_agent, default_user_agent)
  end

  def get_user_agent(_bolt_version, fields) do
    default_user_agent = "BoltSips/" <> to_string(Application.spec(:bolt_sips, :vsn))
    user_agent = Keyword.get(fields, :user_agent, default_user_agent)
    %{user_agent: user_agent}
  end
end
