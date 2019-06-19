# Multi tenancy

When connecting to a Neo4j cluster, `Bolt.Sips` will create 3 distinct connection pools, each of them dedicated to one of the following connection types (**connection roles**):

- `:route` - used for getting information from the Neo4j router, such as: routing details about which server is handling what type of role: read/write, and more.
- `:read` - used for read-only connections
- `:write` - used for write-only connections.

Having the `Bolt.Sips` configured in `routing` mode, will enforce your code to clarify what type of connections you want, type you **must** specify when requesting a `Bolt.Sips` connection. Example:

```elixir
rconn = Bolt.Sips.conn(:read)
wconn = Bolt.Sips.conn(:write)
router_conn = Bolt.Sips.conn(:route)
```

Without being explicit about the connection type, you will receive errors, in case you'll attempt to execute a query that will say: create new nodes, on a server having the role: `read` or `route`.

This is the only rule you must observe, when using the `Bolt.Sips` driver with a causal cluster.
