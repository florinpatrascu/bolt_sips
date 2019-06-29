# Using Bolt.Sips to query the Neo4j server

Let's talk about the basics of querying a Neo4j server, using `Bolt.Sips`, and a few methods you could use for using the data returned by the server, using the `Bolt.Sips.Response`. You can learn so much more from the official docs, available at [Neo4j](https://neo4j.com/developer/graph-database/), you should start from there, if you want to get a deep understanding about the Neo4j graph database and its query language: Cypher.

## What you need?

- a [Neo4j](https://neo4j.com/download/) server running locally and available at this `url`: `bolt://neo4j:test@localhost`
- a mix project with `:bolt_sips` available


## Simple queries, using Cypher

With the above prerequisites, let's drop into the IEx shell and start experimenting.

```sh
cd my_neo4j
iex -S mix
Erlang/OTP 21 [erts-10.2.3] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe]

Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)

iex»
```

First we need to start the driver with a minimalist configuration (unless it is already started by your project?):

```elixir
iex» {:ok, _neo} = Bolt.Sips.start_link(url: "bolt://neo4j:test@localhost")
{:ok, #PID<0.243.0>}
iex»

```

Presuming your database is empty, you can still test your setup by running a simple Cypher query:

```elixir
iex» conn = Bolt.Sips.conn()
#PID<0.248.0>
iex» Bolt.Sips.query!(conn, "RETURN 1 as n") |>
...» Bolt.Sips.Response.first()
%{"n" => 1}
```

and we obtained our first response from the server: `%{"n" => 1}`, w⦿‿⦿t!! Now let's try some more complicated Cypher queries. We'll use examples that you may want to paste them in your `.exs/.ex` files rather than into the IEx shell, for readability.

While most of the Cypher querier fit on a simple row, and they look compact, you might encounter situations where you need to send multiple queries in a single trip, to the server. `Bolt.Sips` allows you do that.

Let's initialize our **test** database with some data.

```elixir
cypher = """
  CREATE (BoltSips:BoltSips {title:'Elixir sipping from Neo4j, using Bolt', released:2016, license:'MIT', bolt_sips: true})
  CREATE (TNOTW:Book {title:'The Name of the Wind', released:2007, genre:'fantasy', bolt_sips: true})
  CREATE (Patrick:Person {name:'Patrick Rothfuss', bolt_sips: true})
  CREATE (Kvothe:Person {name:'Kote', bolt_sips: true})
  CREATE (Denna:Person {name:'Denna', bolt_sips: true})
  CREATE (Chandrian:Deamon {name:'Chandrian', bolt_sips: true})

  CREATE
    (Kvothe)-[:ACTED_IN {roles:['sword fighter', 'magician', 'musician']}]->(TNOTW),
    (Denna)-[:ACTED_IN {roles:['many talents']}]->(TNOTW),
    (Chandrian)-[:ACTED_IN {roles:['killer']}]->(TNOTW),
    (Patrick)-[:WROTE]->(TNOTW)
"""

{:ok, response} =
  Bolt.Sips.conn()
  |> Bolt.Sips.query(cypher)
```

According to the response from the server, this is what we did:

```elixir
iex» response
%Bolt.Sips.Response{
  results: [],
  stats: %{
    "labels-added" => 6,
    "nodes-created" => 6,
    "properties-set" => 19,
    "relationships-created" => 4
  },
  type: "w"
}
```

we have 6 new Nodes, 6 new labels and 4 new relationships.

At any time, if you want to clean up the data we're creating, you can use this query:

`MATCH (n {bolt_sips: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r`

Observe we're adding a `bolt_sips` property to the Nodes we're adding, so that it's easier to refer them in our tests.

Let's see how many nodes of "type" (`label`, according to Cypher's official terminology) `Person` having the property `bolt_sips` true, we have in our database:

```elixir
iex» query = """
...»   MATCH (n:Person {bolt_sips: true})
...»   RETURN n.name AS Name
...»   ORDER BY Name DESC
...»   LIMIT 5
...»  """

iex» %Bolt.Sips.Response{} = response = Bolt.Sips.query!(conn, query)
%Bolt.Sips.Response{
  bookmark: "neo4j:bookmark:v1:tx21613",
  fields: ["Name"],
  notifications: [],
  plan: nil,
  profile: nil,
  records: [["Patrick Rothfuss"], ["Kote"], ["Denna"]],
  results: [
    %{"Name" => "Patrick Rothfuss"},
    %{"Name" => "Kote"},
    %{"Name" => "Denna"}
  ],
  stats: [],
  type: "r"
}
```

We have 3 of them, and we're only showing the `name` property! Above you see the full `Bolt.Sips.Response` returned by our driver based on the raw data returned by the Neo4j server. The `:results` key, contains the aggregated response you will use most of the time, and for that the `Bolt.Sips.Response` module has some useful helpers, for example:

```elixir
iex» response |>
...» Bolt.Sips.Response.first()
%{"Name" => "Patrick Rothfuss"}
```

and much more. Check the `Bolt.Sips.Response`'s own docs, for more.
