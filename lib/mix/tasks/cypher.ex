defmodule Mix.Tasks.Bolt.Cypher do
  use Mix.Task

  @shortdoc "Execute a Cypher command"
  @recursive true

  @moduledoc """
  Quickly run Cypher commands from a mix task

  ## Command line options

    - `--url`, `-u` - Neo4j server URL
    - `--ssl`, `-s` - use ssl

  The command line options have lower precedence than the options
  specified in your `mix.exs` file, if defined.

  Examples:

      MIX_ENV=test mix bolt.cypher "MATCH (people:Person) RETURN people.name LIMIT 5"

      Output sample:

      "MATCH (people:Person) RETURN people.name as name LIMIT 5"
      [%{"name" => "Keanu Reeves"}, %{"name" => "Carrie-Anne Moss"},
       %{"name" => "Andy Wachowski"}, %{"name" => "Lana Wachowski"},
       %{"name" => "Joel Silver"}]
  """

  alias Bolt.Sips, as: Neo4j

  @doc false
  def run(args) do
    Application.ensure_all_started(:bolt_sips)

    {cli_opts, args, _} = OptionParser.parse(args, aliases: [u: :url, s: :ssl])
    options = run_options(cli_opts, Application.get_env(:bolt_sips, Bolt))

    if args == [], do: Mix.raise "Try entering a Cypher command"

    cypher = args |> List.first

    {:ok, pid} = Neo4j.start_link(options)

    # display the cypher command
    log_cypher(cypher)

    case Neo4j.query(pid, cypher) do
      {:ok, row} ->
        row |> log_response
      {:error, code} ->
        log_error("Cannot execute the command, see error above; #{inspect(code)}")
    end
  end

  defp run_options(_, nil) do
    Mix.raise "can't find a valid configuration file, use: MIX_ENV=test mix bolt.cypher \"MATCH...\", for example"
  end

  defp run_options(args, config) do
    Keyword.merge(config, args)
  end

  defp log_cypher(msg), do: Mix.shell.info [:green, "#{inspect(msg)}"]
  defp log_response(msg), do: Mix.shell.info [:yellow, "#{inspect msg}"]
  defp log_error(msg), do: Mix.shell.info [:white, "#{msg}"]

end
