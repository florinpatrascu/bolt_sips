defprotocol Bolt.Sips.ResponseEncoder.Json do
  @moduledoc """
  Protocol controlling how a value is made jsonable.

  Its only purpose is to convert Bolt Sips specific structures into elixir buit-in types
  which can be encoed in json by Jason.

  ## Deriving
  If the provided default implementation don't fit your need, you can override with your own
  implementation.

  ### Example
  Let's assume that you don't want Node's id available as they are Neo4j's ones and are not
  reliable because of id reuse and you want to have you own `uuid` in place.
  Instead of:
  ```
    {
      id: 0,
      labels: ["TestNode"],
      properties: {
        uuid: "837806a7-6c37-4630-9f6c-9aa7ad0129ed"
        value: "my node"
      }
    }
  ```
  you want:
  ```
    {
      uuid: "837806a7-6c37-4630-9f6c-9aa7ad0129ed",
      labels: ["TestNode"],
      properties: {
        value: "my node"
      }
    }
  ```

  You can achieve that with the following implementation:
  ```
  defimpl Bolt.Sips.ResponseEncoder.Json, for: Bolt.Sips.Types.Node do
    def encode(node) do
      new_props = Map.drop(node.properties, :uuid)

      node
      |> Map.from_struct()
      |> Map.put(:uuid, node.properties.uuid)
      |> Map.put(:properties, new_props)
    end
  end
  ```

  It is also possible to provide implementation that returns structs or updated Bolt.Sips.Types,
  the use of a final `Bolt.Sips.ResponseEncoder.Json.encode()` will ensure that these values will
  be converted to jsonable ones.
  """
  @fallback_to_any true

  @doc """
  Convert a value in a jsonable format
  """
  @spec encode(any()) :: any()
  def encode(value)
end

alias Bolt.Sips.{Types, ResponseEncoder}

defimpl ResponseEncoder.Json, for: Types.DateTimeWithTZOffset do
  @spec encode(Types.DateTimeWithTZOffset.t()) :: String.t()
  def encode(value) do
    {:ok, dt} = Types.DateTimeWithTZOffset.format_param(value)
    ResponseEncoder.Json.encode(dt)
  end
end

defimpl ResponseEncoder.Json, for: Types.TimeWithTZOffset do
  @spec encode(Types.TimeWithTZOffset.t()) :: String.t()
  def encode(struct) do
    {:ok, t} = Types.TimeWithTZOffset.format_param(struct)
    ResponseEncoder.Json.encode(t)
  end
end

defimpl ResponseEncoder.Json, for: Types.Duration do
  @spec encode(Types.Duration.t()) :: String.t()
  def encode(struct) do
    {:ok, d} = Types.Duration.format_param(struct)
    ResponseEncoder.Json.encode(d)
  end
end

defimpl ResponseEncoder.Json, for: Types.Point do
  @spec encode(Types.Point.t()) :: map()
  def encode(struct) do
    {:ok, pt} = Types.Point.format_param(struct)
    ResponseEncoder.Json.encode(pt)
  end
end

defimpl ResponseEncoder.Json,
  for: [Types.Node, Types.Relationship, Types.UnboundRelationship, Types.Path] do
  @spec encode(struct()) :: map()
  def encode(value) do
    value
    |> Map.from_struct()
    |> ResponseEncoder.Json.encode()
  end
end

defimpl ResponseEncoder.Json, for: Any do
  @spec encode(any()) :: any()
  def encode(value) when is_list(value) do
    value
    |> Enum.map(&ResponseEncoder.Json.encode/1)
  end

  def encode(%{__struct__: _} = value) do
    value
    |> Map.from_struct()
    |> ResponseEncoder.Json.encode()
  end

  def encode(value) when is_map(value) do
    value
    |> Enum.into(%{}, fn {k, val} -> {k, ResponseEncoder.Json.encode(val)} end)
  end

  def encode(value) do
    value
  end
end
