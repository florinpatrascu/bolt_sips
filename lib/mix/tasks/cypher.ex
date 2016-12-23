defmodule Mix.Tasks.Bolt.Cypher do
  use Mix.Task

  @shortdoc "Execute a Cypher command"
  @recursive true
  @defaults [host: 'localhost', port: 7687]

  @moduledoc """
  Quickly run Cypher commands from a mix task

  ## Command line options

    - `--host`, `-h` - server host
    - `--port`, `-P` - server port
    - `--username`, `-u` - the user name (optional)
    - `--password`, `-p` - password

  The command line options have lower precedence than the options
  specified in your `mix.exs` file, if defined.

  Examples:

      mix bolt.cypher "MATCH (people:Person) RETURN people.name LIMIT 5"

      Output sample:

      "MATCH (people:Person) RETURN people.name as name LIMIT 5"
      [%{"name" => "Keanu Reeves"}, %{"name" => "Carrie-Anne Moss"},
       %{"name" => "Andy Wachowski"}, %{"name" => "Lana Wachowski"},
       %{"name" => "Joel Silver"}]
  """
  ## TODO: use the project's own config file

  alias Bolt.Sips.Response
  alias Boltex.Bolt


  @doc false
  def run(args) do
    {cli_opts, args, _} = OptionParser.parse(args,
                            aliases: [h: :host, P: :port, u: :username,
                                      p: :password])

    if args == [], do: Mix.raise "Try entering a Cypher command"

    cypher = args |> List.first

    options = Keyword.merge(cli_opts, @defaults)


    {:ok, p}   = :gen_tcp.connect options[:host], options[:port],
                      [active: false, mode: :binary, packet: :raw]
    :ok        = Bolt.handshake :gen_tcp, p
    :ok        =

    case Bolt.init :gen_tcp, p, {options[:username], options[:password]} do
     :ok ->
        # display the cypher command
        log_cypher(cypher)

        # and echo the server response too
        Bolt.run_statement(:gen_tcp, p, cypher)
        |> Response.transform
        |> log_response

      {:error, code} -> log_error("Cannot execute the command, see error above")
    end
  end

  defp log_cypher(msg), do: Mix.shell.info [:green, "#{inspect(msg)}"]
  defp log_response(msg), do: Mix.shell.info [:yellow, "#{inspect msg}"]
  defp log_error(msg), do: Mix.shell.info [:white, "#{msg}"]

end
