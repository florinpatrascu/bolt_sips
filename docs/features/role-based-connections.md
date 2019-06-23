# Role-based connections

Starting with the 2.0 version, you can have distinct configurations that you can use in your app, concurrently. These configurations can connect to connect in `:direct` mode to different Neo4j servers, or the same but with different credentials, pool sizes, etc.

> This is not recommended for connecting to a causal cluster; the `:routing` mode, respectively.

To differentiate between multiple `:direct` configurations, you'll use a new parameter: `:role`. Let's see a some code examples, for brevity.

```elixir
frontend_config = [
    url: "bolt://localhost",
    basic_auth: [username: "neo4j", password: "test"],
    pool_size: 10,
    max_overflow: 2,
    role: :frontend
  ]

backend_config = [
    url: "bolt://not_my_localhost:12345",
    basic_auth: [username: "xxxxx", password: "yyyyy"],
    pool_size: 10,
    max_overflow: 2,
    role: :backend
  ]


{:ok, _pid} = Bolt.Sips.start_link(frontend_config)
{:ok, _pid} = Bolt.Sips.start_link(backend_config)

:frontend = Bolt.Sips.conn(:frontend)
:backend = Bolt.Sips.conn(:backend)

%Response{results: [%{"n" => 1}]} = Bolt.Sips.query!(:frontend, "RETURN 1 as n")
%Response{results: [%{"n" => 1}]} = Bolt.Sips.query!(:backend, "RETURN 1 as n")

```

The last two Cypher queries above will be executed on two different servers. And yes you can run them concurrently since their respective pools will not compete for the same resources.

If you desire to terminate a role-based connection, you can easily do so. Just like this: `:ok = Bolt.Sips.terminate_connections(:backend)`.
