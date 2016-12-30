## BoltSips

Neo4j driver for Elixir wrapped around the Bolt protocol.

![Build Status](https://travis-ci.org/florinpatrascu/bolt_sips.svg?branch=master)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/florinpatrascu/bolt_sips.svg)](https://beta.hexfaktor.org/github/florinpatrascu/bolt_sips)
[![Ebert](https://ebertapp.io/github/florinpatrascu/bolt_sips.svg)](https://ebertapp.io/github/florinpatrascu/bolt_sips)

Documentation: http://hexdocs.pm/bolt_sips/


## Disclaimer

`Bolt.Sips` is currently on `0.x` beta releases but it is heading towards a stable release. Please check the issues tracker for more information and outstanding issues.

## Features

  * It is using: Bolt. Neo4j's newest network protocol, designed for high-performance
  * Supports transactions, simple and complex Cypher queries with or w/o parameters
  * Connection pool implementation using: "A hunky Erlang worker pool factory", aka: [Poolboy](http://github.com/devinus/poolboy) :)
  * Supports Neo4j 3.0.x/3.1.x

### Installation

[Available in Hex](https://hex.pm/packages/bolt_sips), the package can be installed as:

#### 1. Add bolt_sips to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:bolt_sips, "~> 0.1"}]
end
```
#### 2. Ensure bolt_sips is started before your application:

```elixir
def application do
  [applications: [:bolt_sips]]
end
```

### Usage

Edit your `config/config.exs` and set Bolt connection, for example:

```elixir
config :bolt_sips, Bolt,
  hostname: 'localhost',
  # basic_auth: [username: "neo4j", password: "*********"],
  port: 7687,
  pool_size: 5,
  max_overflow: 1
```

A new parameter: `url`, can be used for reducing the verbosity of the config files; available starting with  version `0.1.5`. For example:

```elixir
config :bolt_sips, Bolt,
  url: 'localhost:7687',
  pool_size: 5,
  max_overflow: 1
```

And if you are using any remote instances of hosted Neo4j servers, such as the ones available (also for free) at [GrapheneDB.com](http://www.graphenedb.com), configuring the driver is a matter of a simple copy and paste:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://hobby-happyHoHoHo.dbs.graphenedb.com:24786",
  basic_auth: [username: "demo", password: "demo"]
  ssl: true
```

or even simpler:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://demo:demo@hobby-happyHoHoHo.dbs.graphenedb.com:24786",
  ssl: true
```

With a minimalist setup configured as above, and a Neo4j 3.x server running, you can connect to the server and run some queries using Elixir’s interactive shell ([IEx](http://elixir-lang.org/docs/stable/iex/IEx.html)). Example:

```elixir
$ MIX_ENV=test iex -S mix
Erlang/OTP 19 [erts-8.2] [source] [64-bit] [smp: ....

Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)

iex> conn = Bolt.Sips.conn
#Port<0.5312>

iex> Bolt.Sips.query!(conn, "CREATE (a:Person {name:'Bob'})")
%{stats: %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1}, type: "w"}

iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name: 'Bob'}) RETURN a.name AS name") |> Enum.map(&(&1["name"]))

["Bob"]

iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name:'Bob'}) DELETE a")
%{stats: %{"nodes-deleted" => 1}, type: "w"}
```

### Command line

Run simple Cypher commands from a mix task, for quick testing Cypher results or the connection with your server:

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

Tests run against a running instance of Neo4J. Please verify that you do not store critical data on this server!

If you have docker available on your system, you can start an instance before running the test suite:

```shell
docker run --rm -p 7687:7687 -e 'NEO4J_AUTH=none' neo4j:3.0.6
```

```shell
mix test
```

### Special thanks

- Michael Schaefermeyer (@mschae), for implementing the Bolt protocol in Elixir. 

`Bolt.Sips` incorporates the Bolt protocol code originally created at [mschae/boltex](https://github.com/mschae/boltex), for the low level communication with the Neo4j server.  

### Contributors

As reported by Github: [contributions to master, excluding merge commits](https://github.com/florinpatrascu/bolt_sips/graphs/contributors)

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
