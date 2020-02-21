defmodule Bolt.Sips.BoltKitCase do
  @moduledoc """
  tag your tests with `boltkit`, like this:

      @tag boltkit: %{
            url: "neo4j://127.0.0.1:9001/?name=molly&age=1",
            scripts: [
              {"test/scripts/get_routing_table_with_context.script", 9001},
              {"test/scripts/return_x.bolt", 9002}
            ],
            debug: true
          }
  and then use the prefix returned via the context, for working with the stubbed connection(s)

      test "get_routing_table_with_context.script", %{prefix: prefix} do
        assert ...
      end

  """
  @moduletag :boltkit

  use ExUnit.CaseTemplate

  alias Porcelain.Process, as: Proc

  require Logger

  setup_all do
    Porcelain.reinit(Porcelain.Driver.Basic)
  end

  setup %{boltkit: boltkit} do
    prefix = Map.get(boltkit, :prefix, UUID.uuid4())
    url = Map.get(boltkit, :url, "bolt://127.0.0.1")

    porcelains = stub_servers(boltkit)

    pid =
      with {:ok, pid} <- connect(url, prefix) do
        pid
      else
        _ -> raise RuntimeError, "cannot create a Bolt.Sips process"
      end

    on_exit(fn ->
      porcelains
      |> Enum.each(fn
        {:ok, porcelain} ->
          # wait for boltstub to finish
          :timer.sleep(150)

          with true <- Proc.alive?(porcelain),
               %Proc{out: out} <- porcelain do
            try do
              Enum.into(out, IO.stream(:stdio, :line))
            rescue
              _ ->
                Logger.debug("BoltStub's out was flushed.")
                :rescued
            end
          else
            _e ->
              Logger.debug("BoltStub ended prematurely.")
          end

        e ->
          Logger.error(inspect(e))
      end)
    end)

    {:ok, porcelains: porcelains, prefix: prefix, sips: pid, url: url}
  end

  defp stub_servers(%{scripts: scripts} = args) do
    opts =
      if Map.get(args, :debug, false) do
        [out: IO.stream(:stderr, :line)]
      else
        []
      end

    scripts
    |> Enum.map(fn {script, port} ->
      with true <- File.exists?(script) do
        sport = Integer.to_string(port)
        porcelain = Porcelain.spawn("boltstub", [sport, script], opts)
        wait_for_socket('127.0.0.1', port)
        {:ok, porcelain}
      else
        _ -> {:error, script <> ", not found."}
      end
    end)
  end

  @sock_opts [:binary, active: false]
  defp wait_for_socket(address, port) do
      with {:ok, socket} <- :gen_tcp.connect(address, port, @sock_opts, 1000) do
        socket
      end
  end


  defp connect(url, prefix) do
    conf = [
      url: url,
      basic_auth: [username: "neo4j", password: "password"],
      # pool: DBConnection.Ownership,
      pool_size: 1,
      prefix: prefix
      # after_connect_timeout: fn _ -> nil end,
      # queue_timeout: 100,
      # queue_target: 100,
      # queue_interval: 10
    ]

    Logger.debug("creating #{url}, prefix: #{prefix}")
    Bolt.Sips.start_link(conf)
  end
end
