defmodule Bolt.Sips.QueryStatement do
  defstruct statement: ""
end

defimpl DBConnection.Query, for: Bolt.Sips.QueryStatement do
  def describe(query, _), do: query

  def parse(query, _), do: query

  def encode(_query, data, _), do: data

  def decode(_, result, _), do: result
end
