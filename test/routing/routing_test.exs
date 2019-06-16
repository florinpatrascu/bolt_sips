defmodule Bolt.Sips.RoutingTest do
  @moduledoc """

  """
  use Bolt.Sips.BoltKitCase, async: false

  alias Bolt.Sips.Response

  @moduletag :boltkit

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/non_router.script", 9001}
         ]
       }
  test "non_router.script", %{prefix: prefix} do
    assert %{error: error} = Bolt.Sips.routing_table(prefix)
    assert error =~ ~r/not a router/i
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/get_routing_table.script", 9001}
         ]
       }
  test "get_routing_table.script", %{prefix: prefix} do
    assert %{
             read: %{"127.0.0.1:9002" => 0},
             route: %{"127.0.0.1:9001" => 0, "127.0.0.1:9002" => 0},
             write: %{"127.0.0.1:9001" => 0}
           } = Bolt.Sips.routing_table(prefix)

    assert %Bolt.Sips.Response{
             results: [
               %{"name" => "Alice"},
               %{"name" => "Bob"},
               %{"name" => "Eve"}
             ]
           } =
             Bolt.Sips.conn(:read, prefix: prefix)
             |> Bolt.Sips.query!("MATCH (n) RETURN n.name AS name")
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001/?name=molly&age=1",
         scripts: [
           {"test/scripts/get_routing_table_with_context.script", 9001},
           {"test/scripts/return_x.bolt", 9002}
         ]
       }
  test "get_routing_table_with_context.script", %{prefix: prefix} do
    assert %{
             read: %{"127.0.0.1:9002" => 0},
             route: %{"127.0.0.1:9001" => 0, "127.0.0.1:9002" => 0},
             write: %{"127.0.0.1:9001" => 0}
           } = Bolt.Sips.routing_table(prefix)

    Bolt.Sips.conn(:read, prefix: prefix)
    |> Bolt.Sips.query!("RETURN {x}", %{x: 1})
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/router.script", 9001},
           {"test/scripts/create_a.script", 9006}
         ]
       }
  test "create_a.script", %{prefix: prefix} do
    assert %{write: %{"127.0.0.1:9006" => 0}} = Bolt.Sips.routing_table(prefix)

    assert %Response{results: []} =
             Bolt.Sips.conn(:write, prefix: prefix)
             |> Bolt.Sips.query!("CREATE (a $x)", %{x: %{name: "Alice"}})
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/router.script", 9001},
           {"test/scripts/return_1.script", 9004}
         ]
       }
  test "return_1.script", %{prefix: prefix} do
    assert %{read: %{"127.0.0.1:9004" => 0}} = Bolt.Sips.routing_table(prefix)

    assert %Response{results: [%{"x" => 1}]} =
             Bolt.Sips.conn(:read, prefix: prefix)
             |> Bolt.Sips.query!("RETURN $x", %{x: 1})
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/router.script", 9001},
           {"test/scripts/return_1_in_tx_twice.script", 9004},
           {"test/scripts/return_1_in_tx_twice.script", 9005}
         ]
       }
  test "return_1_in_tx_twice.script", %{prefix: prefix} do
    Bolt.Sips.conn(:read, prefix: prefix)
    |> Bolt.Sips.transaction(fn conn ->
      assert %Response{fields: ["1"]} = Bolt.Sips.query!(conn, "RETURN 1")
    end)
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/router.script", 9001},
           {"test/scripts/return_1_twice.script", 9004},
           {"test/scripts/return_1_twice.script", 9005}
         ]
       }
  test "return_1_twice.script", %{prefix: prefix} do
    rconn1 = Bolt.Sips.conn(:read, prefix: prefix)
    rconn2 = Bolt.Sips.conn(:read, prefix: prefix)
    assert %Response{results: [%{"x" => 1}]} = Bolt.Sips.query!(rconn1, "RETURN $x", %{x: 1})
    assert %Response{results: [%{"x" => 1}]} = Bolt.Sips.query!(rconn2, "RETURN $x", %{x: 1})
  end

  @tag boltkit: %{
         url: "neo4j://127.0.0.1:9001",
         scripts: [
           {"test/scripts/router.script", 9001},
           {"test/scripts/forbidden_on_read_only_database.script", 9006}
         ]
       }
  test "forbidden_on_read_only_database.script", %{prefix: prefix} do
    conn = Bolt.Sips.conn(:write, prefix: prefix)

    assert_raise Bolt.Sips.Exception, ~r/unable to write/i, fn ->
      Bolt.Sips.query!(conn, "CREATE (n {name:'Bob'})")
    end
  end
end
