defmodule Config.Test do
  use ExUnit.Case
  alias Bolt.Sips.Utils

  doctest Bolt.Sips

  @graphenedb_like_url "bolt://hobby-happyHoHoHo.dbs.graphenedb.com:24786"

  @basic_tls_config [
    url: @graphenedb_like_url,
    basic_auth: [username: "xmas", password: "Kr1ngl3"],
    ssl: [verify: :verify_none]
  ]

  @light_tls_config [
    url: "bolt://xmas:Kr1ngl3@hobby-happyHoHoHo.dbs.graphenedb.com:24786",
    ssl: true
  ]

  @mixed_config [
    hostname: "127.0.0.1",
    port: 0,
    url: @graphenedb_like_url
  ]

  @basic_config [
    hostname: "hobby",
    basic_auth: [username: "neo4j", password: "neo4j"],
    port: 1234,
    pool_size: 15,
    max_overflow: 3,
    prefix: :default
  ]

  test "parsing the host and the port, from a url string config parameter" do
    config = Utils.default_config(@basic_tls_config)

    assert config[:url] == @graphenedb_like_url
    assert config[:hostname] == "hobby-happyHoHoHo.dbs.graphenedb.com"
    assert config[:basic_auth] == [username: "xmas", password: "Kr1ngl3"]
    assert config[:port] == 24786
    assert config[:ssl] == [verify: :verify_none]
    assert config[:prefix] == :default
  end

  test "url string in config overides the :hostname and the :port" do
    config = Utils.default_config(@mixed_config)

    assert config[:url] == @graphenedb_like_url
    assert config[:hostname] == "hobby-happyHoHoHo.dbs.graphenedb.com"
    assert config[:port] == 24786
  end

  test "standard Bolt.Sips configuration parameters" do
    config = Utils.default_config(@basic_config)

    assert config[:url] == nil
    assert config[:hostname] == "hobby"
    assert config[:basic_auth] == [username: "neo4j", password: "neo4j"]
    assert config[:port] == 1234
    assert config[:ssl] == false
  end

  test "url containing authentication details, the hostname, the protocol and port, all together" do
    config = Utils.default_config(@light_tls_config)

    assert config[:url] != nil
    assert config[:hostname] == "hobby-happyHoHoHo.dbs.graphenedb.com"
    assert config[:basic_auth] == [username: "xmas", password: "Kr1ngl3"]
    assert config[:port] == 24786
    assert config[:ssl] == true
    assert config[:ssl_options] == []
  end

  test "standard Bolt.Sips default configuration" do
    config = Utils.default_config([])

    assert config[:hostname] == "localhost"
    assert config[:port] == 7687
    assert config[:ssl] == false
  end

  test "invalid url in configuration and explicit :port" do
    config = Utils.default_config(url: "example.com", port: 123)

    assert config[:hostname] == nil
    assert config[:port] == 7687
  end

  test "url with routing context" do
    config =
      [url: "bolt+routing://neo4j:password@neo01.graph.example.com:123456?policy=europe"]
      |> Utils.default_config()

    assert config[:routing_context] == %{"policy" => "europe"}
    assert config[:schema] == "bolt+routing"
    assert config[:hostname] == "neo01.graph.example.com"
    assert config[:port] == 123_456
    assert config[:query] == "policy=europe"
    assert config[:basic_auth] == [username: "neo4j", password: "password"]
  end
end
