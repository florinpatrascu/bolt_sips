defmodule Bolt.Sips.Error do
  @moduledoc """
  represents an error message received from the Bolt driver
  """
  alias __MODULE__
  @type t :: %__MODULE__{}

  defstruct [:code, :message]

  # todo: more work to be done here
  def new({:ignored, f} = _r), do: new({:failure, f})
  def new({:failure, %{"code" => code, "message" => message}} = _r) do
    {:error, struct(Error, %{code: code, message: message})}
  end

  def new(r), do: r
end
