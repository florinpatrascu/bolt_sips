defmodule Bolt.Sips.ResponseEncoder.Json.Jason do
  @moduledoc """
  A default implementation for Jason encoding library.

  More info about Jason: [https://hex.pm/packages/jason](https://hex.pm/packages/jason)

  Allow this usage:
  ```
  conn = Bolt.Sips.conn()
  {:ok, res} = Bolt.Sips.query(conn, "MATCH (t:TestNode) RETURN t")
  Jason.encode!(res)
  ```

  Default implementation can be overriden by providing your own implementation.

  More info about implementation: [https://hexdocs.pm/jason/readme.html#differences-to-poison](https://hexdocs.pm/jason/readme.html#differences-to-poison)

  #### Note:
  In order to benefit from Bolt.Sips.ResponseEncoder implementation, use
  `Bolt.Sips.ResponseEncoder.Json.encode` and pass the result to the Jason
  encoding functions.
  """
  alias Bolt.Sips.Types
  alias Bolt.Sips.ResponseEncoder.Json

  defimpl Jason.Encoder, for: [Types.Node, Types.Relationship, Types.Path, Types.Point] do
    @spec encode(struct(), Jason.Encode.opts()) :: iodata()
    def encode(data, opts) do
      data
      |> Json.encode()
      |> Jason.Encode.map(opts)
    end
  end

  defimpl Jason.Encoder, for: [Types.DateTimeWithTZOffset, Types.TimeWithTZOffset, Types.Duration] do
    @spec encode(struct(), Jason.Encode.opts()) :: iodata()
    def encode(data, opts) do
      data
      |> Json.encode()
      |> Jason.Encode.string(opts)
    end
  end
end
