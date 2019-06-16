defmodule One.Test do
  # use Bolt.Sips.RoutingConnCase
  # @moduletag :routing

  # # alias Bolt.Sips.{Success, Error, Response}
  # # alias Bolt.Sips.Types.{Node, Relationship, UnboundRelationship, Path}

  # @tag :routing
  # test "temporary placeholder for focused tests during development/debugging" do
  #   assert %{"r" => 300} ==
  #            Bolt.Sips.conn(:write) |> Bolt.Sips.query!("RETURN 300 AS r") |> List.first()
  # end

  use ExUnit.Case
  alias Bolt.Sips.Response

  test "a simple query" do
    conn = Bolt.Sips.conn()
    response = Bolt.Sips.query!(conn, "RETURN 300 AS r")

    assert %Response{results: [%{"r" => 300}]} = response
    assert response |> Enum.member?("r")
    assert 1 = response |> Enum.count()
    assert [%{"r" => 300}] = response |> Enum.take(1)
    assert %{"r" => 300} = response |> Response.first()
  end

  # @tag :skip
  test "multiple statements" do
    conn = Bolt.Sips.conn()

    q = """
    MATCH (n {bolt_sips: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r;
    CREATE (BoltSip:BoltSip {title:'Elixir sipping from Neo4j, using Bolt', released:2016, license:'MIT', bolt_sips: true});
    MATCH (b:BoltSips{bolt_sips: true}) RETURN b
    """

    l = Bolt.Sips.query!(conn, q)
    assert is_list(l)

    assert 3 ==
             Enum.filter(l, fn
               %Response{} -> true
               _ -> false
             end)
             |> Enum.count()
  end
end
