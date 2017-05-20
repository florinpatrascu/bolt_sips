defmodule Bolt.Sips.Error do
  @moduledoc """
  represents an error message
  """
  alias __MODULE__
  @type t :: %__MODULE__{}

  defstruct [:code, :message]

  def new(%Boltex.Error{code: code, connection_id: cid, function: f, message: message, type: t}) do
    {:error, struct(Error, %{code: code, message: "Details: #{message}; connection_id: #{inspect cid}, function: #{inspect f}, type: #{inspect t}"})}
  end
  def new({:ignored, f} = _r), do: new({:error, f})
  def new({:failure, %{"code" => code, "message" => message}} = _r) do
    {:error, struct(Error, %{code: code, message: message})}
  end
  def new(r), do: r
end
