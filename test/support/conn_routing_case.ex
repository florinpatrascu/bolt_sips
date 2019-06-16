defmodule Bolt.Sips.RoutingConnCase do
  @moduletag :routing

  use ExUnit.CaseTemplate

  alias Bolt.Sips

  @routing_connection_config [
    url: "bolt+routing://localhost:9001",
    basic_auth: [username: "neo4j", password: "test"],
    pool_size: 10,
    max_overflow: 2,
    queue_interval: 500,
    queue_target: 1500,
    retry_linear_backoff: [delay: 150, factor: 2, tries: 2],
    tag: @moduletag
  ]

  setup_all do
    {:ok, _pid} = Sips.start_link(@routing_connection_config)
    conn = Sips.conn(:write)

    on_exit(fn ->
      with conn when not is_nil(conn) <- Sips.conn(:write) do
        Sips.Test.Support.Database.clear(conn)
      else
        e -> {:error, e}
      end
    end)

    {:ok, write_conn: conn}
  end
end
