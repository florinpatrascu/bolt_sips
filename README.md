<img src="assets/logo_transparent.png" alt="logo" width="240"/>

# Neo4j driver for Elixir.

## IMPORTANT

> the `master` branch is observing the development of the 2.0 version! While the new driver architecture is considered stable, this branch should be considered as work in progress! For production, please use the `Bolt.Sips` driver `v1.5.x`, from hex.pm. This branch, while in development, will be available on hex.pm, but please use it with care!

We moved the development in the public area, for offering our users an early preview of what is coming. The documentation for functions and modules, including the new `docs/` sections, is work in progress, pretty much. However, the code is stable and can be used for experimenting with the new features introduced in this version:

- routing
- role based connections
- multi-tenancy
- better support for errors
- and so much more

Contributions and feedback, are very welcome. Thank you!

[![Build Status](https://travis-ci.org/florinpatrascu/bolt_sips.svg?branch=master)](https://travis-ci.org/florinpatrascu/bolt_sips)
[![Hex.pm](https://img.shields.io/hexpm/dt/bolt_sips.svg?maxAge=2592000)](https://hex.pm/packages/bolt_sips)
[![Hexdocs.pm](https://img.shields.io/badge/api-hexdocs-brightgreen.svg)](https://hexdocs.pm/bolt_sips)

`Bolt.Sips` is an Elixir driver for [Neo4j](https://neo4j.com/developer/graph-database/), providing many useful features:

- using the Bolt protocol, the Elixir implementation - the Neo4j's newest network protocol, designed for high-performance; latest Bolt versions, are supported.
- Can connect to a standalone Neo4j server (`:direct` mode) or to a Neo4j causal cluster, using the `bolt+routing` or the newer `neo4j` schemes; connecting in `:routing` mode.
- Provides the user with the ability to create and manage distinct ad-hoc `role-based` connections to one or more Neo4j servers/databases
- Supports transactions, simple and complex Cypher queries with or w/o parameters
- Multi-tenancy
- Supports Neo4j versions: 3.0.x/3.1.x/3.2.x/3.4.x/3.5.x

## Table of Contents

- [Installation](#installation)
  - [Getting Started](docs/getting-started.md#Starting-the-Driver)
  - [Basic usage](docs/getting-started.md#usage)
  - [Configuration](docs/features/configuration.md)
    - [Direct mode](docs/features/configuration.md#direct-mode)
    - [Routing](docs/features/configuration.md#routing-mode)
    - [Role-based connections](docs/features/configuration.md#role-based-connections)
    - [Multi tenancy](docs/features/configuration.md#multi-tenancy)
- [Using Cypher](docs/features/using-cypher.md)
- [Temporal and spatial types](docs/features/using-temporal-and-spatial-types.md)
- [Transactions](docs/features/about-transactions.md)
- [Encoding](docs/features/about-encoding.md)
- [Routing, in detail](docs/features/routing.md)
- [Multi tenancy, in detail](docs/features/multi-tenancy.md)
- [Using Bolt.Sips with Phoenix](docs/features/using-with-phoenix.md)
- [More examples](docs/examples/readme.md)

### Installation

[Available in Hex](https://hex.pm/packages/bolt_sips), the package can be added to your list of dependencies, in the: `mix.exs`:

```elixir
def deps do
  [{:bolt_sips, "~> 2.0.1-rc"}]
end
```

### Basic usage

Provided you have access to a running Neo4j server, and a project where you just added the `:bolt_sips` dependency, run an `iex` session inside the project's folder, and once inside the shell, follow this simple step-by-step example.

Start an iex session:

```elixir
Erlang/OTP 21 [erts-10.2.3] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe]
Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)

iex» {:ok, _neo} = Sips.start_link(url: "bolt://neo4j:test@localhost")
{:ok, #PID<0.237.0>}

iex» conn = Sips.conn()
#PID<0.242.0>

iex» Sips.query!(conn, "return 1 as n") |>
...» Bolt.Sips.Response.first()
%{"n" => 1}
```

Please see the docs for more examples and details about this driver.

### Testing

You'll need a running Neo4j server, for running the tests. Please verify that you do not store critical data on this server, as its contents will be wiped clean when the tests are running.

If you have docker available on your system, you can start an instance before running the test suite:

```shell
docker run --rm -p 7687:7687 -e 'NEO4J_AUTH=neo4j/test' neo4j:3.0.6
```

Neo4j versions used for test: 3.0, 3.1, 3.4, 3.5

```shell
mix test
```

For the stubs using [boltkit](https://github.com/neo4j-drivers/boltkit/), you will have to install Python 3.7 and run: `pip install boltkit`. After this you can run any tests tagged with `:boltkit`. Example:

```shell
mix test test/boltkit_test.exs --include boltkit
```

or:

```shell
mix test --only boltkit
```

### Special thanks

- Michael Schaefermeyer (@mschae), for the initial version of the Bolt protocol in Elixir: [mschae/boltex](https://github.com/mschae/boltex)

### Contributors

As reported by Github: [contributions to master, excluding merge commits](https://github.com/florinpatrascu/bolt_sips/graphs/contributors)

### Contributing

- [Fork it](https://github.com/florinpatrascu/bolt_sips/fork)
- Create your feature branch (`git checkout -b my-new-feature`)
- Test (`mix test`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create new Pull Request

### License

```txt
Copyright 2016-2019 the original author or authors

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
