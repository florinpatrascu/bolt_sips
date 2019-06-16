defmodule Routing.Routing.TableParserTest do
  use ExUnit.Case, async: true
  @moduletag :routing

  alias Bolt.Sips.Routing.RoutingTable

  @valid_routing_table %{
    "servers" => [
      %{
        "addresses" => ["127.0.0.1:9001", "127.0.0.1:9002", "127.0.0.1:9003"],
        "role" => "ROUTE"
      },
      %{"addresses" => ["127.0.0.1:9004", "127.0.0.1:9005"], "role" => "READ"},
      %{"addresses" => ["127.0.0.1:9006"], "role" => "WRITE"}
    ],
    "ttl" => 300
  }

  @magic_routing_table %{
    "servers" => [
      %{
        "addresses" => ["127.0.0.1:9001", "127.0.0.1:9002", "127.0.0.1:9003"],
        "role" => "ROUTE"
      },
      %{"addresses" => ["127.0.0.1:9004", "127.0.0.1:9005"], "role" => "READ"},
      %{"addresses" => ["127.0.0.1:9006"], "role" => "WRITE"},
      %{"addresses" => ["127.0.0.1:9005"], "role" => "WARLOCK"},
      %{"addresses" => ["127.0.0.1:9004"], "role" => "WIZARD"}
    ],
    "ttl" => 300
  }

  describe "Routing table" do
    test "parse a valid server response having valid roles" do
      assert %Bolt.Sips.Routing.RoutingTable{
               roles: %{
                 read: %{"127.0.0.1:9004" => 0, "127.0.0.1:9005" => 0},
                 route: %{
                   "127.0.0.1:9001" => 0,
                   "127.0.0.1:9002" => 0,
                   "127.0.0.1:9003" => 0
                 },
                 write: %{"127.0.0.1:9006" => 0}
               },
               updated_at: route_updated_at,
               ttl: ttl
             } = RoutingTable.parse(@valid_routing_table)

      refute RoutingTable.ttl_expired?(route_updated_at, ttl)
    end

    test "parse a valid server response containing some Magic roles" do
      assert %Bolt.Sips.Routing.RoutingTable{
               roles: %{
                 read: %{"127.0.0.1:9004" => 0, "127.0.0.1:9005" => 0},
                 route: %{
                   "127.0.0.1:9001" => 0,
                   "127.0.0.1:9002" => 0,
                   "127.0.0.1:9003" => 0
                 },
                 write: %{"127.0.0.1:9006" => 0}
               },
               updated_at: route_updated_at,
               ttl: ttl
             } = RoutingTable.parse(@magic_routing_table)

      refute RoutingTable.ttl_expired?(route_updated_at, ttl)
    end
  end
end
