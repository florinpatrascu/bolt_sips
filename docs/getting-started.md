# Getting Started

Let's start by creating a simple Elixir project, as a playground for our tests.

```sh
mix new neo4j_demo --sup --app n4d --module N4D
cd neo4j_demo
```

Open the `mix.exs` and add the bolt_sips dependency.

```elixir
defmodule N4D.MixProject do
  use Mix.Project

  def project do
    [
      app: :n4d,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {N4D.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bolt_sips, "~> 2.0.0-rc"},
      {:jason, "~> 1.1"}
    ]
  end
end
```

we added the [jason](https://hex.pm/packages/jason) library too, for converting the server responses to json. And then run:

```sh
mix do deps.get, compile
```

And our simple project is ready for us to start experimenting with it.

Let's first configure the connection to a running Neo4j server. We presume a standalone community edition server is started and available on the `localhost` interface, and having its Bolt port open at: `7687`. For simplicity edit the `config/config.exs`, and modify it to look like this:

```elixir
use Mix.Config

config :bolt_sips, Bolt,
  url: "bolt://localhost:7687",
  basic_auth: [username: "neo4j", password: "test"],
  pool_size: 10

```

With the project configured to connect to a Neo4j server, in direct mode, we can add `Bolt.Sips` to the app's main supervision tree, and let the OTP manage it.

```elixir
# lib/n4_d/application.ex

defmodule N4D.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)}
    ]

    opts = [strategy: :one_for_one, name: N4D.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

There are a couple of different other ways to start the driver but let's keep it simple for now.

The easiest way to start playing with the driver, in the current configuration, is to drop into the IEx shell and run simple Cypher commands through it.

```sh
cd neo4j_demo
iex -S mix
```

A few examples:

```elixir
iex» alias Bolt.Sips, as: Neo
iex» alias Bolt.Sips.Response

# check the driver is up and running:

iex» Neo.info()
%{
  default: %{
    connections: %{direct: %{"localhost:7687" => 0}, routing_query: nil},
    user_options: [
      socket: Bolt.Sips.Socket,
      port: 7687,
      url: "bolt://localhost:7687",
      # ...
      basic_auth: [username: "neo4j", password: "test"],
      pool_size: 10
    ]
  }
}

# in direct mode, our current configuration, all the operations: read/write or delete, are sent using a
# a common connection (pool). Let's obtain a connection:

iex» conn = Neo.conn()
#PID<0.308.0>

# a few examples:

iex» response = Neo.query!(conn, "CREATE (p:Person)-[:LIKES]->(t:Technology)")
%Response{
  bookmark: nil,
  fields: [],
  notifications: [],
  plan: nil,
  profile: nil,
  records: [],
  results: [],
  stats: %{
    "labels-added" => 2,
    "nodes-created" => 2,
    "relationships-created" => 1
  },
  type: "w"
}

# query with undirected relationship unless sure of direction
%Bolt.Sips.Response{results: results} = response =  Neo.query!(conn, "MATCH (p:Person)-[:LIKES]-(t:Technology) RETURN p")

# where `results` contain this:
[%{"p" => %Bolt.Sips.Types.Node{id: 355, labels: ["Person"], properties: %{}}}]

# we can encode the results to json, as simple as this
iex» Jason.encode!(results)                                                                          "[{\"p\":{\"id\":355,\"labels\":[\"Person\"],\"properties\":{}}}]"

```

Follow this link: [Cypher Basics](https://neo4j.com/developer/cypher-query-language/), for a gentle introduction to Cypher; Neo4j's query language.

The Cypher queries we used above are taken from the page above.
