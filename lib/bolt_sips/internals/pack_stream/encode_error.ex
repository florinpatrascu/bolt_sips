defmodule Bolt.Sips.Internals.PackStream.EncodeError do
  @moduledoc """
  Represents an error when encoding data for the Bolt protocol.

  Shamelessly inspired by @devinus' Poison encoder.
  """

  defexception item: nil, message: nil

  @typedoc """
  Send back the `item` that cannot be encoded with a `message` explaining the  reason why it
  can't be successfully encoded.
  """
  @type t :: %__MODULE__{
          item: map(),
          message: nil | String.t()
        }

  @spec message(map()) :: String.t()
  def message(%{item: item, message: nil}) do
    "unable to encode value: #{inspect(item)}"
  end
end
