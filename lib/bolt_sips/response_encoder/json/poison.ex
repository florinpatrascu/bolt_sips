defmodule Bolt.Sips.ResponseEncoder.Json.Poison do
  @moduledoc """
  A default implementation for Poison encoding library.
  More info about poison here: [https://hex.pm/packages/poison](https://hex.pm/packages/poison)

  Allow this usage:
  ```
  conn = Bolt.Sips.conn()
  {:ok, res} = Bolt.Sips.query(conn, "MATCH (t:TestNode) RETURN t")
  Poison.encode!(res)
  ```

  Default implementation can be overriden by providing your own implementation.

  More info about implementation: [https://hexdocs.pm/poison/Poison.html#module-encoder](https://hexdocs.pm/poison/Poison.html#module-encoder)

  #### Note:
  In order to benefit from Bolt.Sips.ResponseEncoder implementation, use
  `Bolt.Sips.ResponseEncoder.Json.encode` and pass the result to the Poison
  encoding functions.
  """
  alias Bolt.Sips.Types
  alias Bolt.Sips.ResponseEncoder.Json

  defimpl Poison.Encoder, for: [Types.Node, Types.Relationship, Types.Path, Types.Point] do
    @spec encode(struct(), Poison.Encoder.options()) :: iodata

    def encode(data, opts) do
      data
      |> Json.encode()
      |> Poison.Encoder.Map.encode(opts)
    end
  end

  defimpl Poison.Encoder,
    for: [Types.DateTimeWithTZOffset, Types.TimeWithTZOffset, Types.Duration] do
    @spec encode(struct(), Poison.Encoder.options()) :: iodata

    def encode(data, opts) do
      data
      |> Json.encode()
      |> Poison.Encoder.BitString.encode(opts)
    end
  end
end
