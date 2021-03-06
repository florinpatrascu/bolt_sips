defmodule Bolt.Sips.PerformanceTest do
  use Bolt.Sips.ConnCase, async: false

  setup(%{conn: conn} = context) do
    Bolt.Sips.Test.Support.Database.clear(conn)
    {:ok, context}
  end

  @tag :bench
  test "Querying 500 nodes should under 100ms", context do
    conn = context[:conn]

    cql_create =
      1..500
      |> Enum.map(fn x ->
        "CREATE (:Test {value: 'test_#{inspect(x)}'})"
      end)
      |> Enum.join("\n")

    assert %Bolt.Sips.Response{stats: %{"nodes-created" => 500}} =
             Bolt.Sips.query!(Bolt.Sips.conn(), cql_create)

    simple_cypher = """
      MATCH (t:Test)
      RETURN t AS test
    """

    output =
      Benchee.run(
        %{
          # "run" => fn -> query.(conn, simple_cypher) end
          "run" => fn -> Bolt.Sips.Query.query(conn, simple_cypher) end
          # " new conn" => fn -> query.(Bolt.Sips.conn(), simple_cypher) end
        },
        time: 5
      )

    # Query should take less than 50ms in average
    assert Enum.at(output.scenarios, 0).run_time_data.statistics.average < 125_000_000
  end

  @tag :bench
  test "Creating nodes with properties and a long list should take less than 100ms", context do
    conn = context[:conn]

    long_list = Enum.to_list(1..10_000)

    simple_cypher = """
      CREATE (t:Test $props)
      RETURN t AS test
    """

    output =
      Benchee.run(
        %{
          # "run" => fn -> query.(conn, simple_cypher) end
          "run with properties" => fn ->
            Bolt.Sips.Query.query(conn, simple_cypher, %{
              props: %{test_int: 124, test_float: 12.5, list: long_list}
            })
          end
          # " new conn" => fn -> query.(Bolt.Sips.conn(), simple_cypher) end
        },
        time: 5
      )

    # Query should take less than 50ms in average
    assert Enum.at(output.scenarios, 0).run_time_data.statistics.average < 125_000_000
  end
end
