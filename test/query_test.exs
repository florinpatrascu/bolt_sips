defmodule Query.Test do
  use ExUnit.Case, async: true
  alias Query.Test

  defmodule TestUser do
    defstruct name: "", bolt_sips: true
  end

  setup_all do
    # reuse the same connection for all the tests in the suite
    # MATCH (n {bolt_sips: TRUE}) OPTIONAL MATCH (n)-[r]-() DELETE n,r;

    conn = Bolt.Sips.conn
    # assert {:ok, _r} = Bolt.Sips.query(conn, "MATCH (n:Friend {star_friend: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r")

    cypher = """
    MATCH (n {bolt_sips: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r;

    CREATE (BoltSips:BoltSips {title:'Elixir sipping from Neo4j, using Bolt', released:2016, license:'MIT', bolt_sips: true})
    CREATE (TNOTW:Book {title:'The Name of the Wind', released:2007, genre:'fantasy', bolt_sips: true})
    CREATE (Patrick:Person {name:'Patrick Rothfuss', bolt_sips: true})
    CREATE (Kvothe:Person {name:'Kote', bolt_sips: true})
    CREATE (Denna:Person {name:'Denna', bolt_sips: true})
    CREATE (Chandrian:Deamon {name:'Chandrian', bolt_sips: true})

    CREATE
      (Kvothe)-[:ACTED_IN {roles:['sword fighter', 'magician', 'musician']}]->(TNOTW),
      (Denna)-[:ACTED_IN {roles:['many talents']}]->(TNOTW),
      (Chandrian)-[:ACTED_IN {roles:['killer']}]->(TNOTW),
      (Patrick)-[:WROTE]->(TNOTW)
    """
    assert {:ok, _r} = Bolt.Sips.query(conn, cypher)

    # on_exit fn ->
    #   Bolt.Sips.query!(conn, "MATCH (n:Friend {star_friend: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
    #   IO.puts "This is invoked once the test is done"
    # end

    {:ok, [conn: conn]}
  end

  test "a simple query that should work", context do
    conn = context[:conn]

    cyp = """
      MATCH (n:Person {bolt_sips: true})
      RETURN n.name AS Name
      ORDER BY Name DESC
      LIMIT 5
    """
    {:ok, row} = Bolt.Sips.query(conn, cyp)
    assert List.first(row)["Name"] == "Patrick Rothfuss",
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
      {:ok, rows} ->
        refute length(rows) == 0, "Did you initialize the 'The Name of the Wind' database?"
        refute length(rows) > 1, "Kote?! There is only one!"
        assert List.first(rows)["name"] == "Kote", "expecting to find Kote"
      {:error, reason} -> IO.puts "Error: #{reason["message"]}"
    end
  end

  test "executing a Cpyher query, with struct parameters", context do
    conn = context[:conn]

    cypher = """
      CREATE(n:User {props})
    """

    assert {:ok, _} = Bolt.Sips.query(conn, cypher, %{props: %Test.TestUser{name: "Strut", bolt_sips: true}})
  end

  test "executing a Cpyher query, with map parameters", context do
    conn = context[:conn]

    cypher = """
      CREATE(n:User {props})
    """

    assert {:ok, _} = Bolt.Sips.query(conn, cypher, %{props: %{name: "Mep", bolt_sips: true}})
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
    {:ok, r} = Bolt.Sips.query(conn, cypher)

    assert length(r) == 3, "you're missing some characters from the 'The Name of the Wind' db"

    if row = List.first(r) do
      assert row["p"].properties["name"] == "Patrick Rothfuss"
      assert is_map(row["p"]), "was expecting a map `p`"
      assert row["person"]["label"] == "Person"
      assert row["NAME"] == "PATRICK ROTHFUSS"
      assert row["nickname"] == "n/a"
      assert row["p"].properties["bolt_sips"] == true
    else
      IO.puts "Did you initialize the 'The Name of the Wind' database?"
    end
  end

  test "if Patrick Rothfuss wrote The Name of the Wind", context do
    conn = context[:conn]
    cypher = """
      MATCH (p:Person)-[r:WROTE]->(b:Book {title: 'The Name of the Wind'})
      RETURN p
    """

    rows = Bolt.Sips.query!(conn, cypher)
    assert List.first(rows)["p"].properties["name"] == "Patrick Rothfuss"
  end

  test "it returns only known role names", context do
    conn = context[:conn]
    cypher = """
      MATCH (p)-[r:ACTED_IN]->() where p.bolt_sips RETURN r.roles as roles
      LIMIT 25
    """
    rows = Bolt.Sips.query!(conn, cypher)
    roles = ["killer", "sword fighter","magician","musician","many talents"]
    my_roles = Enum.map(rows, &(&1["roles"])) |> List.flatten
    assert my_roles -- roles == [], "found more roles in the db than expected"
  end

  test "path from: MERGE p=({name:'Alice'})-[:KNOWS]-> ...", context do
    conn = context[:conn]
    cypher = """
    MERGE p = ({name:'Alice', bolt_sips: true})-[:KNOWS]->({name:'Bob', bolt_sips: true})
    RETURN p
    """
    path = Bolt.Sips.query!(conn, cypher)
    |> List.first
    |> Map.get("p")

    assert {2,1} == {length(path.nodes), length(path.relationships)}
  end

  test "return a single number from a statement with params", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN {n} AS num", %{n: 10}) |> List.first
    assert row["num"] == 10
  end

  test "run simple statement with complex params", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN {x} AS n", %{"x": %{"abc": ["d", "e", "f"]}}) |> List.first
    assert row["n"]["abc"] == ["d", "e", "f"]
  end

  test "return an array of numbers", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN [10,11,21] AS arr") |> List.first
    assert row["arr"] == [10, 11, 21]
  end

  test "return a string", context do
    conn = context[:conn]
    row = Bolt.Sips.query!(conn, "RETURN 'Hello' AS salute") |> List.first
    assert row["salute"] == "Hello"
  end

  test "UNWIND range(1, 10) AS n RETURN n", context do
    conn = context[:conn]
    rows = Bolt.Sips.query!(conn, "UNWIND range(1, 10) AS n RETURN n")
    assert {1, 10} == rows |> Enum.map(&(&1["n"])) |> Enum.min_max
  end

  test "MERGE (k:Person {name:'Kote'}) RETURN k", context do
    conn = context[:conn]
    k = Bolt.Sips.query!(conn, "MERGE (k:Person {name:'Kote', bolt_sips: true}) RETURN k LIMIT 1") |> List.first
    |> Map.get("k")

    assert k.labels == ["Person"]
    assert k.properties["name"] == "Kote"
  end

  test "query/2 and query!/2", context do
    conn = context[:conn]
    r = Bolt.Sips.query!(conn, "RETURN [10,11,21] AS arr") |> List.first
    assert r["arr"] == [10,11,21]

    assert{:ok, [r]} == Bolt.Sips.query(conn, "RETURN [10,11,21] AS arr")
    assert r["arr"] == [10,11,21]
  end

  test "create a Bob node and check it was deleted afterwards", context do
    conn = context[:conn]
    %{stats: stats} = Bolt.Sips.query!(conn, "CREATE (a:Person {name:'Bob'})")
    assert stats == %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1}

    bob =
      Bolt.Sips.query!(conn, "MATCH (a:Person {name: 'Bob'}) RETURN a.name AS name")
      |> Enum.map(&(&1["name"]))

    assert bob == ["Bob"]

    %{stats: stats} = Bolt.Sips.query!(conn, "MATCH (a:Person {name:'Bob'}) DELETE a")
    assert stats["nodes-deleted"] == 1
  end

  test "Cypher version 3", context do
    conn = context[:conn]
    r = Bolt.Sips.query!(conn, "EXPLAIN RETURN 1") |> List.first
    refute r.plan == nil
    assert Regex.match?(~r/CYPHER 3/iu, r.plan["args"]["version"])
  end

  test "EXPLAIN MATCH (n), (m) RETURN n, m", context do
    conn = context[:conn]
    r = Bolt.Sips.query!(conn, "EXPLAIN MATCH (n), (m) RETURN n, m") |> List.first
    refute r.notifications == nil
    refute r.plan == nil
    assert List.first(r.plan["children"])["operatorType"] == "CartesianProduct"
  end

  test "can execute a query after a failure", context do
    conn = context[:conn]
    assert {:error, _} = Bolt.Sips.query(conn, "INVALID CYPHER")
    assert {:ok, [%{"n" => 22}]} = Bolt.Sips.query(conn, "RETURN 22 as n")
  end
end
