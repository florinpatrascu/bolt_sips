## BoltSips

Neo4j driver for Elixir wrapped around the Bolt protocol.

Documentation: http://hexdocs.pm/bolt_sips/

## Disclaimer

`Bolt.Sips` is currently on `0.x` beta releases but it is heading towards a stable release. Please check the issues tracker for more information and outstanding issues.

## Features

  * It is using: Bolt. Neo4j's newest network protocol, designed for high-performance
  * Supports transactions, simple and complex Cypher queries with or w/o parameters
  * Connection pool implementation using: "A hunky Erlang worker pool factory", aka: [Poolboy](http://github.com/devinus/poolboy) :)
  * Supports Neo4j 3.0.x

### Installation

If [available in Hex](https://hex.pm/packages/bolt_sips), edit the `mix.ex` file and add the `bolt_sips` dependency to the `deps/1 `function. This will add `bolt_sips` to your list of dependencies in `mix.exs`

```elixir
def deps do
  [{:bolt_sips, "~> 0.1"}]
end
```
or from Github:

```elixir
defp deps do
  [{:bolt_sips, github: "florinpatrascu/bolt_sips"}]
end
```

If you're using a local development copy (example):

```elixir
defp deps do
  [{:bolt_sips, path: "../bolt_sips"}]
end
```

Add the `bolt_sips` dependency the applications list:

```elixir
def application do
  [applications: [:logger, :bolt_sips], mod: {Bolt.Sips.Application, []}]
end
```

### Usage

Edit the `config/config.exs` and describe a Bolt server endpoint, your logging preferences, etc. Example:

```elixir
config :bolt_sips, Bolt,
  hostname: 'localhost',
  # basic_auth: [username: "neo4j", password: "*********"],
  port: 7687,
  pool_size: 5,
  max_overflow: 1

level = if System.get_env("DEBUG") do
  :debug
else
  :info
end

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

config :mix_test_watch,
  clear: true
```

*Please observe this issue: [#7773](https://github.com/neo4j/neo4j/issues/7773) if your server requires basic authentication and have issues changing the `username`*

Run `mix do deps.get, deps.compile`

Also, ensure `bolt_sips` is started before your application:

```elixir
def application do
  [applications: [:bolt_sips]]
end
```

With a minimalist setup configured as above, and a Neo4j 3.x server running, you can connect to the server and run some queries using Elixir’s interactive shell ([IEx](http://elixir-lang.org/docs/stable/iex/IEx.html)):

    iex> {:ok, _p} = Bolt.Sips.start_link(host: "localhost")    
    iex> conn = Bolt.Sips.conn
    iex> Bolt.Sips.query!(conn, "CREATE (a:Person {name:'Bob'})")
    %{stats: %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1}, type: "w"}
    
    iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name: 'Bob'}) RETURN a.name AS name") |> Enum.map(&(&1["name"]))
    
    ["Bob"]
    
    iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name:'Bob'}) DELETE a")
    %{stats: %{"nodes-deleted" => 1}, type: "w"}

### Command line

You can also run Cypher commands from a mix task:

    mix bolt.cypher "MATCH (people:Person) RETURN people.name LIMIT 5"

Output sample:

    "MATCH (people:Person) RETURN people.name as name LIMIT 5"

```elixir    
[%{"name" => "Keanu Reeves"}, %{"name" => "Carrie-Anne Moss"},
 %{"name" => "Andy Wachowski"}, %{"name" => "Lana Wachowski"},
 %{"name" => "Joel Silver"}]
```

Available command line options:

- `--host`, `-h` - server host
- `--port`, `-P` - server port
- `--username`, `-u` - the user name (optional)
- `--password`, `-p` - password

### Testing

    mix test

This runs the test suite against a test instance of Neo4j. Please verify that you do not store critical data on this server!

### Special thanks

- Michael Schaefermeyer (@mschae), for implementing the Bolt protocol in Elixir. 

`Bolt.Sips` is using a fork of the [Boltex](https://github.com/mschae/boltex) repository, for the low level communication with the Neo4j server.

### Contributing

- [Fork it](https://github.com/florinpatrascu/bolt_sips/fork)
- Create your feature branch (`git checkout -b my-new-feature`)
- Test (`mix test`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create new Pull Request

### Author

Florin T.PATRASCU (Github: @florinpatrascu, Twitter: @florin)

### License

```
Copyright 2016 Florin T. PATRASCU

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
