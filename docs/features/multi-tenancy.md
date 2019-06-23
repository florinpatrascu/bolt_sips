# Multi tenancy

Very similar to the role-based connections, with multi-tenancy you will be able to connect to servers where the type of the server (role) is defined by the server itself, such as the Neo4j causal cluster. This setting is sill in its infancy, it works, but you'll have to be careful when using it.

For differentiating about Neo4j tenants, we introduced a new configurations parameter, named: `:prefix`. Example:

```elixir
monster_cluster_conf = [
  url: "neo4j://localhost",
  basic_auth: [username: "neo4j", password: "password"],
  retry_linear_backoff: [delay: 150, factor: 1, tries: 1],
  pool_size: 50,
  prefix: :monster_cluster

baby_monster_cluster_conf = [
  url: "neo4j://raspberry_π",
  basic_auth: [username: "πs", password: "4VR"],
  retry_linear_backoff: [delay: 150, factor: 1, tries: 1],
  pool_size: 50,
  prefix: :baby_monster_cluster
```

In the example above we defined two different connections, each of them pointing to different Neo4j clusters. As you know now, every cluster will have role-specific connections as defined by the routers, in those clusters. The connection roles will be: `:write`, `:read` and `:route`. To specify what connection you want and on what server, you will use the `:prefix` optional parameter of the new `Bolt.Sips.conn/2` method. Example:

```elixir
Bolt.Sips.conn(:read, prefix: :monster_cluster)
  |> Bolt.Sips.query!("MATCH (n) RETURN n.name AS name")
```

or:

```elixir
Bolt.Sips.conn(:read, prefix: :baby_monster_cluster)
  |> Bolt.Sips.query!("MATCH (n) RETURN n.name AS name")
```

(wip)
