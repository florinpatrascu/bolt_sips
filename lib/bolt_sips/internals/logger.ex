defmodule Bolt.Sips.Internals.Logger do
  @moduledoc false
  # Designed to log Bolt protocol message between Client and Server.
  #
  # The `from` parameter must be a atom, either `:client` or `:server`
  require Logger

  @doc """
  Produces a formatted Log for a message

  ## Example
      iex> Logger.log_message(:client, {:init, []})
  """
  def log_message(from, {type, data}) do
    msg_type = type |> Atom.to_string() |> String.upcase()
    do_log_message(from, fn -> "#{msg_type} ~ #{inspect(data)}" end)
  end

  @doc """
  Produces a formatted Log

  ## Example
      iex> Logger.log_message(:server, :handshake, 2)
  """
  def log_message(from, type, data) do
    if Application.get_env(:bolt_sips, :log) do
      log_message(from, {type, data})
    end
  end

  @doc """
  Produces a formatted Log for a message
  Data will be output in hexadecimal

  ## Example
      iex> Logger.log_message(:server, :handshake, <<0x02>>)
  """
  def log_message(from, type, data, :hex) do
    if Application.get_env(:bolt_sips, :log_hex, false) do
      msg_type = type |> Atom.to_string() |> String.upcase()

      do_log_message(from, fn ->
        "#{msg_type} ~ #{inspect(data, base: :hex, limit: :infinity)}"
      end)
    end
  end

  defp do_log_message(from, func) when is_function(func) do
    from_txt =
      case from do
        :server -> "S"
        :client -> "C"
      end

    Logger.debug(fn -> "#{from_txt}: #{func.()}" end)
  end
end
