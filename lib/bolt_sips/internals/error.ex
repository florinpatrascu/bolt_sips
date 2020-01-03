defmodule Bolt.Sips.Internals.Error do
  @moduledoc false
  defexception [:message, :code, :connection_id, :function, :type]

  @type t :: %__MODULE__{
          message: String.t(),
          code: nil | any(),
          connection_id: nil | integer(),
          function: atom(),
          type: atom()
        }

  @doc false
  # Produce a Bolt.Sips.Internals.Error depending on the context.
  @spec exception(any(), nil | port(), atom()) :: Bolt.Sips.Internals.Error.t()
  def exception(%{"message" => message, "code" => code}, pid, function) do
    %Bolt.Sips.Internals.Error{
      message: message,
      code: code,
      connection_id: get_id(pid),
      function: function,
      type: :cypher_error
    }
  end

  def exception({:error, :closed}, pid, function) do
    %Bolt.Sips.Internals.Error{
      message: "Port #{inspect(pid)} is closed",
      connection_id: get_id(pid),
      function: function,
      type: :connection_error
    }
  end

  def exception({:failure, %Bolt.Sips.Internals.Error{message: message, code:  code} = err}, pid, function) do
    err
  end
  def exception(message, pid, function) do
    %Bolt.Sips.Internals.Error{
      message: message_for(function, message),
      connection_id: get_id(pid),
      function: function,
      type: :protocol_error
    }
  end

  @spec message_for(nil | atom(), any()) :: String.t()
  defp message_for(:handshake, "HTTP") do
    """
    Handshake failed.
    The port expected a HTTP request.
    This happens when trying to Neo4J using the REST API Port (default: 7474)
    instead of the Bolt Port (default: 7687).
    """
  end

  defp message_for(:handshake, bin) when is_binary(bin) do
    """
    Handshake failed.
    Expected 01:00:00:00 as a result, received: #{inspect(bin, base: :hex)}.
    """
  end

  defp message_for(:handshake, other) do
    """
    Handshake failed.
    Expected 01:00:00:00 as a result, received: #{inspect(other)}.
    """
  end

  defp message_for(nil, message) do
    """
    Unknown failure: #{inspect(message)}
    """
  end

  defp message_for(_function, {:error, error}) do
    case error |> :inet.format_error() |> to_string do
      "unknown POSIX error" -> to_string(error)
      other -> other
    end
  end

  defp message_for(_function, {:ignored, []}) do
    """
    The session is in a failed state and ignores further messages. You need to
    `ACK_FAILURE` or `RESET` in order to send new messages.
    """
  end

  defp message_for(function, message) do
    """
    #{function}: Unknown failure: #{inspect(message)}
    """
  end

  @spec get_id(any()) :: nil | integer()
  defp get_id({:sslsocket, {:gen_tcp, port, _tls, _unused_yet}, _pid}) do
    get_id(port)
  end

  defp get_id(port) when is_port(port) do
    case Port.info(port, :id) do
      {:id, id} -> id
      nil -> nil
    end
  end

  defp get_id(_), do: nil
end
