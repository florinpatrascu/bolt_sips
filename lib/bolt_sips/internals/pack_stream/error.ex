defmodule Bolt.Sips.Internals.PackStreamError do
  @moduledoc false

  # Represents an error when encoding data for the Bolt protocol.

  defexception data_type: nil, data: nil, message: nil, bolt_version: nil

  @typedoc """
  Send back the `item` that cannot be encoded with a `message` explaining the  reason why it
  can't be successfully encoded.
  """
  @type t :: %__MODULE__{
          data_type: atom(),
          data: any(),
          message: String.t(),
          bolt_version: integer()
        }

  def message(%{data_type: nil, data: data, message: message, bolt_version: bolt_version}) do
    "#{message} [bolt_version: #{inspect(bolt_version)}, data: #{inspect(data)}]"
  end

  def message(%{data_type: data_type, data: data, message: message, bolt_version: bolt_version}) do
    "#{message} [bolt_version: #{inspect(bolt_version)}, data_type: #{data_type}, data: #{
      inspect(data)
    }]"
  end
end
