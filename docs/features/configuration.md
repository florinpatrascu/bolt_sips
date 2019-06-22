# Configuration

Bolt.Sips can be configured using the well known Mix config files, or by using simple keyword lists.

This is the most basic configuration:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://localhost:7687"
```

It tells Bolt.Sips your Neo4j server is available locally, and it listens on port 7687, expecting bolt commands.

These are the values you can configure, and their default values:

- `:url`- a full url to pointing to a running Neo4j server. Please remember you must specify the scheme used to connect to the server. Valid schemes:`bolt`,`bolt+routing`and`neo4j` - the last two being used for connecting to a Neo4j causal cluster.
- `:pool_size` - the size of the connection pool. Default: 15
- `:timeout` - a timeout value defined in milliseconds. Default: 15_000
- `:ssl`-`true`, if the connection must be encrypted. Default:`false`
- `:retry_linear_backoff`- the retry mechanism parameters. Also expected, the following parameters:`:delay`,`:factor`and`:tries`. Default value:`retry_linear_backoff: [delay: 150, factor: 2, tries: 3]`
- `:prefix`- used for differentiating between multiple connections available in the same app. Default:`:default`

## Examples of configurations

Connecting to remote (hosted) Neo4j servers, such as the ones available (also for free) at [Neo4j/Sandbox](https://neo4j.com/sandbox-v2/):

```elixir
config :bolt_sips, Bolt,
  url: "bolt://<ip_address>:<bolt_port>",
  basic_auth: [username: "neo4j", password: "#######"]
  ssl: true
```

We also support retrying sending the requests to the servers, using a linear backoff, and try them a couple of times before giving up - all these as part of the existing pool management, of course. Example:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://<ip_address>:<bolt_port>",
  basic_auth: [username: "neo4j", password: "#######"]
  ssl: true
  timeout: 15_000,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3]
```

In the configuration above, the retry will linearly increase the delay from `150ms` following a Fibonacci pattern, cap the delay at `15 seconds` (the value defined by the `:timeout` parameter) and giving up after `3` attempts.

## Direct mode

Until this version, `Bolt.Sips` was used for connecting to a single Neo4j server from the moment the hosting app started, until the hosting app was terminated/restarted. This is known as the: `direct` mode. In `direct` mode, the `Bolt.Sips` driver has one configuration describing the connection to a single Neo4j server.

Since this connection mode is well known to our users, we'll not spend time on talking about it. It is sufficient to say that in direct mode, you have one configurable pool of connections, and the settings governing them i.e. timeout, retry, size, etc., are all about this single connection.

Because starting with version 2.0 `Bolt.Sips` is supporting a new type of connectivity: `routing`, for connecting to multiple servers or to a Neo4j causal cluster, you must specify the `scheme` in the `url` parameter, of your configuration. Example, for configuring a connection in `direct` mode:

    url: "bolt://localhost:7687"

We'll spend more ink on talking about the `routing` mode, next.

## Routing mode

With the 2.0 version, `Bolt.Sips` is implementing the ability to connect your app to a Neo4j causal cluster. You can read more about this, here: [Neo4j Causal Clustering](https://neo4j.com/docs/operations-manual/current/clustering/introduction/)

The features of using a causal cluster, in Neo4j's own words:

> Neo4j’s Causal Clustering provides three main features:
>
> - Safety: Core Servers provide a fault tolerant platform for transaction processing which will remain available while a simple majority of those Core Servers are functioning.
> - Scale: Read Replicas provide a massively scalable platform for graph queries that enables very large graph workloads to be executed in a widely distributed topology.
> - Causal consistency: when invoked, a client application is guaranteed to read at least its own writes.

To configure `Bolt.Sips` for connecting to a Neo4j Causal Cluster, you only need the specify the appropriate scheme, in the `url` configuration parameter:

    url: "bolt+routing://localhost:7687"

or:

    url: "neo4j://localhost:7687"

Prefer the latter, since `bolt+routing` appears to be soon deprecated, by Neo4j. We'll use `neo4j://` throughout the docs for referring to the `routing` mode, for brevity. Read more about `routing`, [here](routing.md).

## Role based connections

When we implemented the routing mode, we realized we could extend this ability to letting you define any number of connections, identified by a role name of your choice. For example, say your default configuration for `Bolt.Sips` looks like this:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://localhost:7687",
  basic_auth: [username: "neo4j", password: "test"],
  pool_size: 10,
  max_overflow: 2,
```

`Bolt.Sips` will load it by default, when your application starts. And with a configuration like that, the default mode, you will continue to obtain connections using the default `Bolt.Sips.conn()` function.

However, if you require to have different connections, say: to a different Neo4j server that has some specific role, you could add a new configuration, for example:

```elixir
config :bolt_sips, :hidden_gems,
  url: "bolt://localhost:1234",
  pool_size: 50,
  role: :hidden_gems
```

You'd have to load this config separately, after the starting the `Bolt.Sips`driver. Like this:

```elixir
iex» Bolt.Sips.start_link(Application.get_env(:bolt_sips, :hidden_gems))
{:ok, #PID<0.266.0>}
```

and the you can use connections from this new configuration, as easy as this:

```elixir
iex» conn = Bolt.Sips.conn(:hidden_gems)
#PID<0.324.0>
```

while for obtaing the connections from your default configuration, is business as usual:

```elixir
iex» conn = Bolt.Sips.conn()
#PID<0.309.0>
```

The new connection pool is supervised by the main `Bolt.Sips.ConnectionSupervisor`, you don't have to do anythings special for that.

![](../images/role_based_connections.png?raw=true)

In the final release, we'll add a friendlier api for adding role-based connections. More details about role-based-connections, [here](role-based-connections.md)

## Multi tenancy

Another important feature of the 2.0 version, is: **multi-tenancy**.

Starting with this version, your app can connect to any number of Neo4j servers, in `direct` mode or `routing`.

We introduced a new configurable parameter, named: `prefix`.

At this time, the only way to configure the driver for multi-tenancy, is programmatically, not via the configuration file. Example:

```elixir
my_secret_cluster_config [
    url: "neo4j://localhost:9001",
    basic_auth: [username: "neo4j", password: "test"],
    pool_size: 10,
    max_overflow: 2,
    queue_interval: 500,
    queue_target: 1500,
    retry_linear_backoff: [delay: 150, factor: 2, tries: 2],
    prefix: :secret_cluster
  ]

{:ok, _pid} = Bolt.Sips.start_link(@routing_connection_config)
conn = Bolt.Sips.conn(:write, prefix: :secret_cluster)
```

And you can start as many connections as needed, for as long as the `:prefix` has different names. These connections can be used for connecting to the same or different Neo4j servers.

More details about multi-tenancy, [here](multi-tenancy.md)
