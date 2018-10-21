![](icon-60x60@3x.png)

Bolt-Sips, the Neo4j driver for Elixir wrapped around the Bolt protocol.

[![Build Status](https://travis-ci.org/florinpatrascu/bolt_sips.svg?branch=master)](https://travis-ci.org/florinpatrascu/bolt_sips)
[![Ebert](https://ebertapp.io/github/florinpatrascu/bolt_sips.svg)](https://ebertapp.io/github/florinpatrascu/bolt_sips)
[![Hex.pm](https://img.shields.io/hexpm/dt/bolt_sips.svg?maxAge=2592000)](https://hex.pm/packages/bolt_sips)
[![Hexdocs.pm](https://img.shields.io/badge/api-hexdocs-brightgreen.svg)](https://hexdocs.pm/bolt_sips)

Documentation: http://hexdocs.pm/bolt_sips/

# Disclaimer

This is a new generation of `Bolt.Sips`: v1.0.nn - transitioning to a new driver design

It is implementing the [db_connection](https://github.com/elixir-ecto/db_connection) database connection behavior.

## Features

* It is using: Bolt. The Neo4j's newest network protocol, designed for high-performance
* Supports transactions, simple and complex Cypher queries with or w/o parameters
* Supports Neo4j versions: 3.0.x/3.1.x/3.2.x/3.4.x

## Breaking changes introduced in version 1.x

* non-closure based transactions are not supported anymore. This is a change introduced in DBConnection 2.x. `Bolt.Sips` version tagged `v0.5.10` is the last version supporting open transactions.
* the support for ETLS was dropped. It was mostly used for development or hand-crafted deployments

### Installation

[Available in Hex](https://hex.pm/packages/bolt_sips), the package can be installed as:

#### 1. Add bolt_sips to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:bolt_sips, "~> 1.0"}]
end
```

#### 2. Ensure bolt_sips is started before your application:

```elixir
def application do
  [applications: [:bolt_sips], mod: {Bolt.Sips.Application, []}]
end
```

You can also specify custom configuration settings in you app's mix config file. These may overwrite your config file:

```elixir
def application do
  [extra_applications: [:logger], mod:
    {Bolt.Sips.Application, [url: 'localhost', pool_size: 15]}
  ]
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

And if you are using any remote instances of hosted Neo4j servers, such as the ones available (also for free) at [Neo4j/Sandbox(https://neo4j.com/sandbox-v2/) configuring the driver is a matter of a simple copy and paste:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://<ip_address>:<bolt_port>",
  basic_auth: [username: "neo4j", password: "#######"]
  ssl: true
```

We’re also retrying sending the requests to the Neo4j server, with a linear backoff, and try them a couple of times before giving up - all these as part of the existing pool management, of course. Example

```elixir
config :bolt_sips, Bolt,
  url: "bolt://<ip_address>:<bolt_port>",
  basic_auth: [username: "neo4j", password: "#######"]
  ssl: true
  timeout: 15_000,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3]
```

In the configuration above, the retry will linearly increase the delay from `150ms` following a Fibonacci pattern, cap the delay at `15 seconds` (the value defined by the `:timeout` parameter) and giving up after `3` attempts.

But you can reduce the configuration even further, and rely on the driver's default values. For example: given you're running a Neo4j server on your local machine and Bolt is enabled on **7687**, this is the simplest configuration you need, in order to get you started:

```elixir
config :bolt_sips, Bolt,
  url: "localhost:7687"
```

With a minimalist setup configured as above, and the Neo4j 3.x server running, you can connect to the server and run some queries using Elixir’s interactive shell ([IEx](http://elixir-lang.org/docs/stable/iex/IEx.html)). Example:

```elixir
$ MIX_ENV=test iex -S mix
Erlang/OTP 21 [erts-10.0.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe]

Interactive Elixir (1.7.3) - press Ctrl+C to exit (type h() ENTER for help)
iex> {:ok, pid} = Bolt.Sips.start_link(url: "localhost")
{:ok, #PID<0.191.0>}

iex> conn = Bolt.Sips.conn
:bolt_sips_pool

iex> Bolt.Sips.query!(conn, "CREATE (a:Person {name:'Bob'})")
%{
  stats: %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1},
  type: "w"
}

iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name: 'Bob'}) RETURN a.name AS name") |> Enum.map(&(&1["name"]))

["Bob"]

iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name:'Bob'}) DELETE a")
%{stats: %{"nodes-deleted" => 1}, type: "w"}

iex> Bolt.Sips.query!(conn, "MATCH (a:Person {name: 'Bob'}) RETURN a.name AS name") |> Enum.map(&(&1["name"]))
[]
```

### Using Bolt.Sips with Phoenix, or similar

Don't forget to start the `Bolt.Sips` driver in your supervision tree. Example:

```elixir
defmodule MoviesElixirPhoenix do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      %{
        id: MoviesElixirPhoenix.Endpoint,
        start: {MoviesElixirPhoenix.Endpoint, :start_link, []}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MoviesElixirPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MoviesElixirPhoenix.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

The code above was extracted from [the Neo4j Movies Demo](https://github.com/florinpatrascu/bolt_movies_elixir_phoenix), a Phoenix web application using this driver and the well known [Dataset - Movie Database](https://neo4j.com/developer/movie-database/).

### Command line

Run simple Cypher commands from a mix task, for quick testing Cypher results or the connection with your server:

    MIX_ENV=test mix bolt.cypher "MATCH (people:Person) RETURN people.name LIMIT 5"

Output sample:

    "MATCH (people:Person) RETURN people.name LIMIT 5"

```elixir
[
  %{"people.name" => "Keanu Reeves"},
  %{"people.name" => "Carrie-Anne Moss"},
  %{"people.name" => "Laurence Fishburne"},
  %{"people.name" => "Hugo Weaving"},
  %{"people.name" => "Lilly Wachowski"}
]
```

Available command line options:

* `--url`, `-u` - server host
* `--ssl`, `-s` - use ssl

For example, if your server requires authentication:

```shell
MIX_ENV=test mix bolt.cypher --ssl true --url "bolt://<user>:<password>@happy-warlocks.dbs.graphenedb.com:24786"\
 "MATCH (people:Person) RETURN people.name LIMIT 5"
```

### Testing

Tests run against a running instance of Neo4j. Please verify that you do not store critical data on this server!

If you have docker available on your system, you can start an instance before running the test suite:

```shell
docker run --rm -p 7687:7687 -e 'NEO4J_AUTH=none' neo4j:3.0.6
```

```shell
mix test
```

### Special thanks

* Michael Schaefermeyer (@mschae), for implementing the Bolt protocol in Elixir: [mschae/boltex](https://github.com/mschae/boltex)

### Contributors

As reported by Github: [contributions to master, excluding merge commits](https://github.com/florinpatrascu/bolt_sips/graphs/contributors)

### Contributing

* [Fork it](https://github.com/florinpatrascu/bolt_sips/fork)
* Create your feature branch (`git checkout -b my-new-feature`)
* Test (`mix test`)
* Commit your changes (`git commit -am 'Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create new Pull Request

### Author

Florin T.PATRASCU (@florin, on Twitter)

### License

```txt
Copyright 2016-2018 Florin T.PATRASCU

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
