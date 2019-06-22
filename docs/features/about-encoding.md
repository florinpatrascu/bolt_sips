# About encoding

Bolt.Sips provides support for encoding your query result in different formats.
For now, only JSON is supported.

There is two way of encoding data to json:

- By using the helpers provided by the module `Bolt.Sips.ResponseEncoder`
- Using your usual JSON encoding library. `Bolt.Sips` have implementation for: Jason and Poison. With this the query results can be automatically encoded by one of the libraries available: Jason or Poison. No further work is required when using a framework like: Phoenix, for example.

A few examples around the encoding suport:

```elixir
iex> query_result = [
   %{
     "t" => %Bolt.Sips.Types.Node{
       id: 26,
       labels: ["Test"],
       properties: %{
         "created_at" => "2019-08-03T12:34:56+01:00",
         "name" => "A test node",
         "uid" => 12345
       }
     }
   }
 ]

# Using Bolt.Sips.ResponseEncoder
 iex> Bolt.Sips.ResponseEncoder.encode(query_result, :json)
{:ok,
 "[{\"t\":{\"id\":26,\"labels\":[\"Test\"],\"properties\":{\"created_at\":\"2019-08-03T12:34:56+01:00\",\"name\":\"A test node\",\"uid\":12345}}}]"}
iex(11)> Bolt.Sips.ResponseEncoder.encode!(query_result, :json)
"[{\"t\":{\"id\":26,\"labels\":[\"Test\"],\"properties\":{\"created_at\":\"2019-08-03T12:34:56+01:00\",\"name\":\"A test node\",\"uid\":12345}}}]"

# Using Jason
iex(14)> Jason.encode!(query_result)
"[{\"t\":{\"id\":26,\"labels\":[\"Test\"],\"properties\":{\"created_at\":\"2019-08-03T12:34:56+01:00\",\"name\":\"A test node\",\"uid\":12345}}}]"

# Using Poison
iex(13)> Poison.encode!(query_result)
"[{\"t\":{\"properties\":{\"uid\":12345,\"name\":\"A test node\",\"created_at\":\"2019-08-03T12:34:56+01:00\"},\"labels\":[\"Test\"],\"id\":26}}]"
```

Both solutions rely on protocols, then they can be easily overridden if needed.
More info in the modules `Bolt.Sips.ResponseEncoder.Json`, `Bolt.Sips.ResponseEncoder.Json.Jason`, `Bolt.Sips.ResponseEncoder.Json.Poison`
