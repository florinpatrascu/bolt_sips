defmodule Large.Param.Set.Test do
  use ExUnit.Case
  doctest Bolt.Sips

  setup_all do
    {:ok, [conn: Bolt.Sips.conn()]}
  end

  @doc """
  Boltex.Bolt.generate_chunks fails with too much data
  test provided by @adri, for issue #16
  """
  test "executing a Cypher query, with large set of parameters", context do
    conn = context[:conn]

    cypher = """
      MATCH (n:Person {bolt_sips: true})
      FOREACH (i IN $largeRange| SET n.test = TRUE )
    """

    case Bolt.Sips.query(conn, cypher, %{largeRange: Enum.to_list(0..1_000_000)}) do
      {:ok, stats} ->
        assert stats["properties-set"] > 0, "Expecting many properties set"

      {:error, reason} ->
        IO.puts("Error: #{reason["message"]}")
    end
  end
end
