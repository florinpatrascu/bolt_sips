defmodule Query.Test do
  use Bolt.Sips.ConnCase, async: true

  alias Query.Test
  alias Bolt.Sips.Test.Support.Database
  alias Bolt.Sips.Response

  defmodule TestUser do
    defstruct name: "", bolt_sips: true
  end

  defp rebuild_fixtures(conn) do
    Database.clear(conn)
    Bolt.Sips.Fixture.create_graph(conn, :bolt_sips)
  end

  setup(%{conn: conn} = context) do
    rebuild_fixtures(conn)
    {:ok, context}
  end

  test "a simple query that should work", context do
    conn = context[:conn]

    cyp = """
      MATCH (n:Person {bolt_sips: true})
      RETURN n.name AS Name
      ORDER BY Name DESC
      LIMIT 5
    """

    {:ok, %Response{} = row} = Bolt.Sips.query(conn, cyp)

    assert Response.first(row)["Name"] == "Patrick Rothfuss",
           "missing 'The Name of the Wind' database, or data incomplete"
  end

  test "A procedure call failure should send reset and not lock the db", context do
    expected_neo4j = System.get_env("NEO4J_VERSION", "3.0.0")

    if Version.match?(expected_neo4j, "~> 3.5.0") do
      conn = context[:conn]

      cyp_fail = """
        CALL db.index.fulltext.queryNodes(\"topic_label\", \"badparen)\") YIELD node RETURN node
      """

      {:error, %Bolt.Sips.Error{code: "Neo.ClientError.Procedure.ProcedureCallFailed"}} =
        Bolt.Sips.query(conn, cyp_fail)

      cyp = """
        MATCH (n:Person {bolt_sips: true})
        RETURN n.name AS Name
        ORDER BY Name DESC
        LIMIT 5
      """

      {:ok, %Response{} = row} = Bolt.Sips.query(conn, cyp)

      assert Response.first(row)["Name"] == "Patrick Rothfuss",
             "missing 'The Name of the Wind' database, or data incomplete"
    end
  end

  @tag :apoc
  test "Passing a timeout option to the query should prevent a timeout", context do
    conn = context[:conn]

    cyp_wait = """
      CALL apoc.util.sleep(20000) RETURN 1 as test
    """

    {:ok, %Response{} = _row} = Bolt.Sips.query(conn, cyp_wait, %{}, timeout: 21_000)
  end

  @tag :apoc
  test "After a timeout, subsequent queries should work", context do
    conn = context[:conn]

    cyp_wait = """
      CALL apoc.util.sleep(10000) RETURN 1 as test
    """

    {:error, _} = Bolt.Sips.query(conn, cyp_wait, %{}, timeout: 5_000)

    cyp = """
      MATCH (n:Person {bolt_sips: true})
      RETURN n.name AS Name
      ORDER BY Name DESC
      LIMIT 5
    """

    {:ok, %Response{} = row} = Bolt.Sips.query(conn, cyp)

    assert Response.first(row)["Name"] == "Patrick Rothfuss",
           "missing 'The Name of the Wind' database, or data incomplete"
  end

  test "executing a Cypher query, with parameters", context do
    conn = context[:conn]

    cypher = """
      MATCH (n:Person {bolt_sips: true})
      WHERE n.name = {name}
      RETURN n.name AS name
    """

    case Bolt.Sips.query(conn, cypher, %{name: "Kote"}) do
      {:ok, %Response{} = rows} ->
        refute Enum.count(rows) == 0,
               "Did you initialize the 'The Name of the Wind' database?"

        refute Enum.count(rows) > 1, "Kote?! There is only one!"
        assert Response.first(rows)["name"] == "Kote", "expecting to find Kote"

      {:error, reason} ->
        IO.puts("Error: #{reason["message"]}")
    end
  end

  test "executing a Cypher query, with struct parameters", context do
    conn = context[:conn]

    cypher = """
      CREATE(n:User {props})
    """

    assert {:ok,
            %Response{
              stats: %{
                "labels-added" => 1,
                "nodes-created" => 1,
                "properties-set" => 2
              },
              type: "w"
            }} =
             Bolt.Sips.query(conn, cypher, %{
               props: %Test.TestUser{name: "Strut", bolt_sips: true}
             })
  end

  test "executing a Cpyher query, with map parameters", context do
    conn = context[:conn]

    cypher = """
      CREATE(n:User {props})
    """

    assert {:ok, %Response{}} =
             Bolt.Sips.query(conn, cypher, %{props: %{name: "Mep", bolt_sips: true}})
  end

  test "executing a raw Cypher query with alias, and no parameters", context do
    conn = context[:conn]

    cypher = """
      MATCH (p:Person {bolt_sips: true})
      RETURN p, p.name AS name, upper(p.name) as NAME,
             coalesce(p.nickname,"n/a") AS nickname,
             { name: p.name, label:head(labels(p))} AS person
      ORDER BY name DESC
    """

    {:ok, %Response{} = r} = Bolt.Sips.query(conn, cypher)

    assert Enum.count(r) == 3,
           "you're missing some characters from the 'The Name of the Wind' db"

    if row = Response.first(r) do
      assert row["p"].properties["name"] == "Patrick Rothfuss"
      assert is_map(row["p"]), "was expecting a map `p`"
      assert row["person"]["label"] == "Person"
      assert row["NAME"] == "PATRICK ROTHFUSS"
      assert row["nickname"] == "n/a"
      assert row["p"].properties["bolt_sips"] == true
    else
      IO.puts("Did you initialize the 'The Name of the Wind' database?")
    end
  end

  test "if Patrick Rothfuss wrote The Name of the Wind", context do
    conn = context[:conn]

    cypher = """
      MATCH (p:Person)-[r:WROTE]->(b:Book {title: 'The Name of the Wind'})
      RETURN p
    """

    %Response{} = rows = Bolt.Sips.query!(conn, cypher)
    assert Response.first(rows)["p"].properties["name"] == "Patrick Rothfuss"
  end

  test "it returns only known role names", context do
    conn = context[:conn]

    cypher = """
      MATCH (p)-[r:ACTED_IN]->() where p.bolt_sips RETURN r.roles as roles
      LIMIT 25
    """

    %Response{results: rows} = Bolt.Sips.query!(conn, cypher)
    roles = ["killer", "sword fighter", "magician", "musician", "many talents"]
    my_roles = Enum.map(rows, & &1["roles"]) |> List.flatten()
    assert my_roles -- roles == [], "found more roles in the db than expected"
  end

  test "path from: MERGE p=({name:'Alice'})-[:KNOWS]-> ...", context do
    conn = context[:conn]

    cypher = """
    MERGE p = ({name:'Alice', bolt_sips: true})-[:KNOWS]->({name:'Bob', bolt_sips: true})
    RETURN p
    """

    path =
      Bolt.Sips.query!(conn, cypher)
      |> Response.first()
      |> Map.get("p")

    assert {2, 1} == {length(path.nodes), length(path.relationships)}
  end

  test "return a single number from a statement with params", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN {n} AS num", %{n: 10}) |> Response.first()
    assert row["num"] == 10
  end

  test "run simple statement with complex params", context do
    conn = context[:conn]

    row =
      Bolt.Sips.query!(conn, "RETURN {x} AS n", %{x: %{abc: ["d", "e", "f"]}})
      |> Response.first()

    assert row["n"]["abc"] == ["d", "e", "f"]
  end

  test "return an array of numbers", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN [10,11,21] AS arr") |> Response.first()
    assert row["arr"] == [10, 11, 21]
  end

  test "return a string", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN 'Hello' AS salute") |> Response.first()
    assert row["salute"] == "Hello"
  end

  test "UNWIND range(1, 10) AS n RETURN n", context do
    conn = context[:conn]

    assert %Response{results: rows} = Bolt.Sips.query!(conn, "UNWIND range(1, 10) AS n RETURN n")

    assert {1, 10} == rows |> Enum.map(& &1["n"]) |> Enum.min_max()
  end

  test "MERGE (k:Person {name:'Kote'}) RETURN k", context do
    conn = context[:conn]

    k =
      Bolt.Sips.query!(conn, "MERGE (k:Person {name:'Kote', bolt_sips: true}) RETURN k LIMIT 1")
      |> Response.first()
      |> Map.get("k")

    assert k.labels == ["Person"]
    assert k.properties["name"] == "Kote"
  end

  test "query/2 and query!/2", context do
    conn = context[:conn]

    assert r = Bolt.Sips.query!(conn, "RETURN [10,11,21] AS arr")
    assert [10, 11, 21] = Response.first(r)["arr"]

    assert {:ok, %Response{} = r} = Bolt.Sips.query(conn, "RETURN [10,11,21] AS arr")
    assert [10, 11, 21] = Response.first(r)["arr"]
  end

  test "create a Bob node and check it was deleted afterwards", context do
    conn = context[:conn]

    assert %Response{stats: stats} = Bolt.Sips.query!(conn, "CREATE (a:Person {name:'Bob'})")
    assert stats == %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1}

    assert ["Bob"] ==
             Bolt.Sips.query!(conn, "MATCH (a:Person {name: 'Bob'}) RETURN a.name AS name")
             |> Enum.map(& &1["name"])

    assert %Response{stats: stats} =
             Bolt.Sips.query!(conn, "MATCH (a:Person {name:'Bob'}) DELETE a")

    assert stats["nodes-deleted"] == 1
  end

  test "Cypher version 3", context do
    conn = context[:conn]

    assert %Response{plan: plan} = Bolt.Sips.query!(conn, "EXPLAIN RETURN 1")
    refute plan == nil
    assert Regex.match?(~r/CYPHER 3/iu, plan["args"]["version"])
  end

  test "EXPLAIN MATCH (n), (m) RETURN n, m", context do
    conn = context[:conn]

    assert %Response{notifications: notifications, plan: plan} =
             Bolt.Sips.query!(conn, "EXPLAIN MATCH (n), (m) RETURN n, m")

    refute notifications == nil
    refute plan == nil

    assert "CartesianProduct" ==
             plan["children"]
             |> List.first()
             |> Map.get("operatorType")
  end

  test "can execute a query after a failure", context do
    conn = context[:conn]
    assert {:error, _} = Bolt.Sips.query(conn, "INVALID CYPHER")
    assert {:ok, %Response{results: [%{"n" => 22}]}} = Bolt.Sips.query(conn, "RETURN 22 as n")
  end

  test "negative numbers are returned as negative numbers", context do
    conn = context[:conn]
    assert {:ok, %Response{results: [%{"n" => -1}]}} = Bolt.Sips.query(conn, "RETURN -1 as n")
  end

  test "return a simple node", context do
    conn = context[:conn]

    assert %Response{
             results: [
               %{
                 "p" => %Bolt.Sips.Types.Node{
                   id: _,
                   labels: ["Person"],
                   properties: %{"bolt_sips" => true, "name" => "Patrick Rothfuss"}
                 }
               }
             ]
           } = Bolt.Sips.query!(conn, "MATCH (p:Person {name: 'Patrick Rothfuss'}) RETURN p")
  end

  test "Simple relationship", context do
    conn = context[:conn]

    cypher = """
      MATCH (p:Person)-[r:WROTE]->(b:Book {title: 'The Name of the Wind'})
      RETURN r
    """

    assert %Response{
             results: [
               %{
                 "r" => %Bolt.Sips.Types.Relationship{
                   end: _,
                   id: _,
                   properties: %{},
                   start: _,
                   type: "WROTE"
                 }
               }
             ]
           } = Bolt.Sips.query!(conn, cypher)
  end

  test "simple path", context do
    conn = context[:conn]

    cypher = """
    MERGE p = ({name:'Alice', bolt_sips: true})-[:KNOWS]->({name:'Bob', bolt_sips: true})
    RETURN p
    """

    assert %Response{
             results: [
               %{
                 "p" => %Bolt.Sips.Types.Path{
                   nodes: [
                     %Bolt.Sips.Types.Node{
                       id: _,
                       labels: [],
                       properties: %{"bolt_sips" => true, "name" => "Alice"}
                     },
                     %Bolt.Sips.Types.Node{
                       id: _,
                       labels: [],
                       properties: %{"bolt_sips" => true, "name" => "Bob"}
                     }
                   ],
                   relationships: [
                     %Bolt.Sips.Types.UnboundRelationship{
                       end: nil,
                       id: _,
                       properties: %{},
                       start: nil,
                       type: "KNOWS"
                     }
                   ],
                   sequence: [1, 1]
                 }
               }
             ]
           } = Bolt.Sips.query!(conn, cypher)
  end

  test "transaction (commit)", context do
    conn = context[:conn]

    Bolt.Sips.transaction(conn, fn conn ->
      book =
        Bolt.Sips.query!(conn, "CREATE (b:Book {title: \"The Game Of Trolls\"}) return b")
        |> Response.first()

      assert %{"b" => g_o_t} = book
      assert g_o_t.properties["title"] == "The Game Of Trolls"
    end)

    %Response{} =
      books = Bolt.Sips.query!(conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")

    assert 1 == Enum.count(books)

    # Clean data

    rem_books = "MATCH (b:Book {title: \"The Game Of Trolls\"}) DELETE b"
    Bolt.Sips.query!(conn, rem_books)
  end

  test "transaction (rollback)", context do
    conn = context[:conn]

    Bolt.Sips.transaction(conn, fn conn ->
      book =
        Bolt.Sips.query!(conn, "CREATE (b:Book {title: \"The Game Of Trolls\"}) return b")
        |> Response.first()

      assert %{"b" => g_o_t} = book
      assert g_o_t.properties["title"] == "The Game Of Trolls"
      Bolt.Sips.rollback(conn, :changed_my_mind)
    end)

    assert %Response{} =
             r = Bolt.Sips.query!(conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")

    assert Enum.count(r) == 0
  end
end
