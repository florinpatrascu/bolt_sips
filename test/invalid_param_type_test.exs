defmodule Bolt.Sips.InvalidParamType.Test do
  use ExUnit.Case

  setup_all do
    {:ok, [conn: Bolt.Sips.conn()]}
  end

  test "executing a Cypher query, with invalid parameter value yields an error", context do
    conn = context[:conn]

    cypher = """
      MATCH (n:Person {invalid: {an_elixir_datetime}}) RETURN TRUE
    """

    {:error, [code: :failure, message: message]} =
      Bolt.Sips.query(conn, cypher, %{an_elixir_tuple: {:not, :valid}})

    assert String.match?(message, ~r/unable to encode value: {:not, :valid}/i)
  end
end
