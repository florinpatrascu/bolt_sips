defmodule Bolt.Sips.Routing.ConnectionsTest do
  use ExUnit.Case, async: true
  @moduletag :routing

  alias Bolt.Sips.Router

  @current_connections %{
    read: %{"localhost:7688" => 10, "localhost:7689" => 20},
    route: %{
      "localhost:7687" => 2,
      "localhost:7688" => 1,
      "localhost:7689" => 9
    },
    routing_query: %{
      params: %{props: %{}},
      query: "call dbms.cluster.routing.getRoutingTable($props)"
    },
    ttl: 300,
    updated_at: 1_555_705_797,
    write: %{"localhost:7687" => 200, "localhost:7690" => 500}
  }

  @new_connections %{
    read: %{"localhost:7688" => 0},
    route: %{"localhost:7687" => 0},
    write: %{"localhost:7689" => 0}
  }

  describe "Router" do
    test "connection information, after refresh" do
      assert %{
               read: %{"localhost:7688" => 0},
               route: %{"localhost:7687" => 0},
               write: %{"localhost:7689" => 0},
               routing_query: %{
                 params: %{props: %{}},
                 query: "call dbms.cluster.routing.getRoutingTable($props)"
               },
               ttl: 300
             } = Router.merge_connections_maps(@current_connections, @new_connections)
    end
  end
end
