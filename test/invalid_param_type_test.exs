defmodule Bolt.Sips.InvalidParamType.Test do
  use ExUnit.Case

  setup_all do
    {:ok, [conn: Bolt.Sips.conn]}
  end

  test "executing a Cypher query, with invalid parameter value yields an error", context do
    conn = context[:conn]

    cypher = """
    MATCH (n:Person {invalid: {an_elixir_datetime}}) RETURN TRUE
    """

    {:error, [code: :failure, message: message]} =
      Bolt.Sips.query(conn, cypher, %{an_elixir_datetime: DateTime.utc_now})

    assert message
  end
end
