defmodule Bolt.Sips.BoltStubTest do
  @moduledoc """
  !!Remember!!
    you cannot reuse the boltstub across the tests, therefore must use a
    unique prefix or use the one returned by the BoltKitCase
  """
  use Bolt.Sips.BoltKitCase, async: false

  @moduletag :boltkit

  @tag boltkit: %{
         url: "bolt://127.0.0.1:9001",
         scripts: [
           {"test/scripts/return_x.bolt", 9001}
         ],
         debug: true
       }
  test "test/scripts/return_x.bolt", %{prefix: prefix} do
    assert %Bolt.Sips.Response{results: [%{"x" => 1}]} =
             Bolt.Sips.conn(:direct, prefix: prefix)
             |> Bolt.Sips.query!("RETURN $x", %{x: 1})
  end

  @tag boltkit: %{
         url: "bolt://127.0.0.1:9001",
         scripts: [
           {"test/scripts/count.bolt", 9001}
         ]
       }
  test "test/scripts/count.bolt", %{prefix: prefix} do
    assert %Bolt.Sips.Response{
             results: [
               %{"n" => 1},
               %{"n" => 2},
               %{"n" => 3},
               %{"n" => 4},
               %{"n" => 5},
               %{"n" => 6},
               %{"n" => 7},
               %{"n" => 8},
               %{"n" => 9},
               %{"n" => 10}
             ]
           } =
             Bolt.Sips.conn(:direct, prefix: prefix)
             |> Bolt.Sips.query!("UNWIND range(1, 10) AS n RETURN n")
  end
end
