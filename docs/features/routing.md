# Routing

Let's walkthrough a simple experiment with using `Bolt.Sips` in routing mode and a Neo4j cluster.

If you don't have a local server, or a remote Neo4j cluster available for your tests, you can easily setup your own local playground. All you need is Docker.

We'll use a [docker-compose.yml](../../docker-compose.yml) file that you can find in the `Bolt.Sips` main source repo.

If you have:

- [Docker](<https://en.wikipedia.org/wiki/Docker_(software)>) installed, and running. You can get Docker from here: https://docs.docker.com/installation/
- and a simple Elixir project having the `:bolt_sips` driver installer, as a dependency

### Start the Neo4j cluster

In a folder where you have the `docker-compose.yml` file, start a new shell session and run the following command:

    docker-compose up

If this is the first time you run this command, or use Neo4j as a Docker image, then based on the quality of your Internet connection, you'll wait a few seconds while Docker downloads a Neo4j Enterprise image. You'll see something like this:

```sh
Creating network "neo4j_lan" with the default driver
Pulling core1 (neo4j:3.5.3-enterprise)...
3.5.3-enterprise: Pulling from library/neo4j
e7c96db7181b: Pull complete
f910a506b6cb: Pull complete
b6abafe80f63: Pull complete
b95a7fd32595: Pull complete
6c09128ad074: Pull complete
648805e5f471: Pull complete
e2790f69a70d: Pull complete
Creating core2 ... done
Creating core3 ... done
Creating core1 ... done
Attaching to core3, core1, core2
core3    | Changed password for user 'neo4j'.
core1    | Changed password for user 'neo4j'.
core2    | Changed password for user 'neo4j'.
core3    | Active database: graph.db
core3    | Directories in use:
core3    |   home:         /var/lib/neo4j
core3    |   config:       /var/lib/neo4j/conf
...
```

and towards the end of the starting sequence, this:

```sh
core2    | 2019-06-17 12:37:59.078+0000 INFO  Remote interface available at http://localhost:7475/
core3    | 2019-06-17 12:37:59.165+0000 INFO  Remote interface available at http://localhost:7476/
```

Check to see if you can connect to your local Neo4j cluster, as simple as pointing your Internet browser to this url: `http://localhost:7474`, and if everything was executed succesfully, you'll be seeing the familiar Neo4j web interface.

Now let's play with the `Bolt.Sips`driver and our local Neo4j cluster.

Change your elixir test project configuration and modify the `config/config.exs` file like this (excerpt):

```elixir
use Mix.Config

config :bolt_sips, Bolt,
  # bolt+routing will be deprecated?!
  # url: "bolt+routing://localhost:7687",
  url: "neo4j://localhost:7687",
  basic_auth: [username: "neo4j", password: "test"],
  pool_size: 10
```

then start a IEx shell session, from the projects'r main folder: `iex -S mix`. While inside the IEx session, let's see if our configuration is sound?

```elixir
iex» Bolt.Sips.info()
%{
  default: %{
    connections: %{
      read: %{"localhost:7688" => 0, "localhost:7689" => 0},
      route: %{
        "localhost:7687" => 0,
        "localhost:7688" => 0,
        "localhost:7689" => 0
      },
      write: %{"localhost:7687" => 0},
      routing_query: %{...},
      ttl: 300,
      updated_at: 1560775628
    },
    user_options: [
      url: "neo4j://localhost:7687",
      pool_size: 10,
      ....
    ]
  }
}
```

if you see the response above, it means your settings are ready. Without going into much details about the data structure above, the routing details are these:

```elixir
  read: %{"localhost:7688" => 0, "localhost:7689" => 0},
  write: %{"localhost:7687" => 0},
  route: %{
    "localhost:7687" => 0,
    "localhost:7688" => 0,
    "localhost:7689" => 0
  ttl: 300,
  updated_at: ...
```

According to the routing information returned by our cluster, we have:

- two nodes accepting `:read` commands: `localhost:7688` and`localhost:7689`
- three nodes capabale of responding with routing specific details: `localhost:7687` `localhost:7688` and `localhost:7689`
- one node accepting `:write` commands; the `localhost:7687`, respectively.

But don't worry about the gory details, we got you covered :)

Let's run some Cypher queries.

```elixir
iex» alias Bolt.Sips.Response
iex» alias Bolt.Sips, as: Neo

# obtaining a read(only) connection:
iex» rconn = Neo.conn(:read)
#PID<0.324.0>

# checking if there are any Person nodes "named": Bob?
iex» %Response{results: r} = Neo.query!(rconn, "MATCH (p:Person{name: 'Bob'}) RETURN p")
%Bolt.Sips.Response{
  bookmark: "neo4j:bookmark:v1:tx2",
  fields: ["p"],
  notifications: [],
  plan: nil,
  profile: nil,
  records: [],
  results: [],
  stats: [],
  type: "r"
}

# r is [], meaning: our query found none. So let's create one.
# First we obtain a connection suitable for `write` operations:
iex» wconn = Neo.conn(:write)
#PID<0.384.0>

# and now we can use it for creating a new node:

iex» %Response{results: r} = Neo.query!(wconn, "CREATE (p:Person{name:'Bob'})")
%Bolt.Sips.Response{
  ...
  stats: %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1},
  type: "w"
}

# our node was created and has one property set,  w⦿‿⦿t!
# but can we find it? Rerun the previous query using the `read` connection:

iex» Neo.query!(rconn, "MATCH (p:Person{name: 'Bob'}) RETURN p") |> Response.first()
%{
  "p" => %Bolt.Sips.Types.Node{
    id: 20,
    labels: ["Person"],
    properties: %{"name" => "Bob"}
  }
}

# and yessss, our new Person node is in the cluster!
# Do you need its json form, instead? Easy:
iex» Neo.query!(rconn, "MATCH (p:Person{name: 'Bob'}) RETURN p") |>
...» Response.first() |>
...» Bolt.Sips.ResponseEncoder.encode!(:json)
"{\"p\":{\"id\":20,\"labels\":[\"Person\"],\"properties\":{\"name\":\"Bob\"}}}"

```

But what happens if we try to create a new Person, using our `read` connection?

```elixir
iex» Neo.query!(rconn, "CREATE (p:Person{name:'Alice'})")
** (Bolt.Sips.Exception) ... No write operations are allowed directly on this database. Writes must pass through the leader. The role of this server is: FOLLOWER
```

Neo4j will promptly let us know we can't use that connection for write operations. This is the main difference that you must consider when coding.

Same command executed on the proper (write) connection, will be successful:

```elixir
iex» Neo.query!(wconn, "CREATE (p:Person{name:'Alice'})")
%Bolt.Sips.Response{
  ...
  stats: %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1},
  type: "w"
}
```
