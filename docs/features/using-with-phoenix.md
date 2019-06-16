# Using Bolt.Sips with Phoenix, or similar

Don't forget to start the `Bolt.Sips` driver in your supervision tree. Example:

```elixir
defmodule MoviesElixirPhoenix do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      %{
        id: MoviesElixirPhoenix.Endpoint,
        start: {MoviesElixirPhoenix.Endpoint, :start_link, []}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MoviesElixirPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MoviesElixirPhoenix.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

The code above was extracted from [the Neo4j Movies Demo](https://github.com/florinpatrascu/bolt_movies_elixir_phoenix), a Phoenix web application using this driver and the well known [Dataset - Movie Database](https://neo4j.com/developer/movie-database/).

Note: as explained below, you don't need to convert your query result before having it  encoded in JSON. BoltSips provides Jason and Poison implementation to tackle this problem automatically.
