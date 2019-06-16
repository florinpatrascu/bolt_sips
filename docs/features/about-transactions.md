# About transactions

Transaction management in Neo4j 3.5+ differs from what it was in prior versions.
The cypher keyword `BEGIN`, `COMMIT` and `ROLLBACK` are no longer available.
In order to have query that runs fine in all versions, it is encouraged to use the following transaction pattern:

```elixir
# Commit is performed automatically if everythings went fine
conn = Bolt.Sips.conn()
Bolt.Sips.transaction(conn, fn conn ->
  result = Bolt.Sips.query!(conn, "CREATE (m:Movie {title: "Matrix"}) RETURN m")
end)

# Rollback is performed automatically in case of error
Bolt.Sips.transaction(conn, fn conn ->
  result =Bolt.Sips.query!(conn, "Invalid query")
end)

# Rollback can stil be forced
Bolt.Sips.transaction(conn, fn conn ->
  result = Bolt.Sips.query!(conn, "CREATE (m:Movie {title: "Matrix"}) RETURN m")
  Bolt.Sips.rollback(conn, :dont_save)
end)
```