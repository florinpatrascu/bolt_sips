defmodule Bolt.Sips.Routing.CrudTest do
  use Bolt.Sips.RoutingConnCase
  @moduletag :routing

  alias Bolt.Sips

  describe "Basic Read/Write; " do
    test "read" do
      cypher = "return 10 as n"

      assert [%{"n" => 10}] ==
               Sips.query!(Sips.conn(:read), cypher)
    end

    test "write" do
      conn = Sips.conn(:write)
      cypher = "CREATE (elf:Elf { name: $name, from: $from, klout: 99 })"

      assert %{
               stats: %{
                 "labels-added" => 1,
                 "nodes-created" => 1,
                 "properties-set" => 3
               },
               type: "w"
             } == Sips.query!(conn, cypher, %{name: "Arameil", from: "Sweden"})
    end

    # https://neo4j.com/docs/cypher-manual/current/clauses/set/#set-adding-properties-from-maps
    test "update" do
      create_cypher = "CREATE (p:Person { first: $person.first, last: $person.last })"

      update_cypher = """
      MATCH (p:Person{ first: 'Green', last: 'Alien' })
        SET p.first = { person }.first, p.last = $person.last
        RETURN p.first as first_name, p.last as last_name
      """

      conn = Sips.conn(:write)

      assert %{
               stats: %{
                 "labels-added" => 1,
                 "nodes-created" => 1,
                 "properties-set" => 2
               },
               type: "w"
             } ==
               Sips.query!(conn, create_cypher, %{person: %{first: "Green", last: "Alien"}})

      assert [%{"last_name" => "Alien"}] ==
               Sips.query!(
                 conn,
                 "MATCH (p:Person { first: 'Green', last: 'Alien' }) RETURN p.last AS last_name"
               )

      assert [%{"first_name" => "Florin", "last_name" => "Pătraşcu"}] ==
               Sips.query!(conn, update_cypher, %{person: %{first: "Florin", last: "Pătraşcu"}})
    end

    test "upsert" do
      # MERGE (p:Person{ first: { map }.name, last: { map }.last }
      # ON CREATE SET n = { map }
      # ON MATCH  SET n += { map }
    end
  end
end
