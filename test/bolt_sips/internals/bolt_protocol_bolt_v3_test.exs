defmodule Bolt.Sips.Internals.BoltProtocolBoltV3Test do
  use ExUnit.Case, async: true
  @moduletag :bolt_v3

  alias Bolt.Sips.Internals.BoltProtocol
  alias Bolt.Sips.Metadata
  alias Bolt.Sips.Utils

  setup do
    app_config = Application.get_env(:bolt_sips, Bolt)

    port = Keyword.get(app_config, :port, 7687)
    auth = {app_config[:basic_auth][:username], app_config[:basic_auth][:password]}

    config =
      app_config
      |> Keyword.put(:port, port)
      |> Keyword.put(:auth, auth)
      |> Utils.default_config()

    {:ok, port} =
      config[:hostname]
      |> String.to_charlist()
      |> :gen_tcp.connect(config[:port],
        active: false,
        mode: :binary,
        packet: :raw
      )

    {:ok, bolt_version} = BoltProtocol.handshake(:gen_tcp, port, [])
    {:ok, _} = BoltProtocol.hello(:gen_tcp, port, bolt_version, auth)

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, config: config, port: port, bolt_version: bolt_version}
  end

  describe "run/7" do
    test "(no params, no metadata, no options)", %{port: port, bolt_version: bolt_version} do
      assert {:ok, {:success, _}} =
               BoltProtocol.run(:gen_tcp, port, bolt_version, "RETURN 1 AS num")
    end

    test "(params, no metadata, no options)", %{port: port, bolt_version: bolt_version} do
      assert {:ok, {:success, _}} =
               BoltProtocol.run(:gen_tcp, port, bolt_version, "RETURN $num AS num", %{num: 14})
    end

    test "(no params, metadata, no options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert {:ok, {:success, _}} =
               BoltProtocol.run(:gen_tcp, port, bolt_version, "RETURN 1 AS num", %{}, metadata)
    end

    test "(params, metadata, no options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert {:ok, {:success, _}} =
               BoltProtocol.run(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN $num AS num",
                 %{num: 14},
                 metadata
               )
    end

    test "(no params, no metadata, options)", %{port: port, bolt_version: bolt_version} do
      assert {:ok, {:success, _}} =
               BoltProtocol.run(:gen_tcp, port, bolt_version, "RETURN 1 AS num", %{}, %{},
                 recv_timeout: 5000
               )
    end

    test "(params, no metadata, options)", %{port: port, bolt_version: bolt_version} do
      assert {:ok, {:success, _}} =
               BoltProtocol.run(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN $num AS num",
                 %{num: 14},
                 %{},
                 recv_timeout: 5000
               )
    end

    test "(no params, metadata, options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert {:ok, {:success, _}} =
               BoltProtocol.run(:gen_tcp, port, bolt_version, "RETURN 1 AS num", %{}, metadata,
                 recv_timeout: 5000
               )
    end

    test "(params, metadata, options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert {:ok, {:success, _}} =
               BoltProtocol.run(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN $num AS num",
                 %{num: 14},
                 metadata,
                 recv_timeout: 5000
               )
    end

    test "Bolt >=2 run syntax should upscale nicely", %{port: port, bolt_version: bolt_version} do
      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocol.run(:gen_tcp, port, bolt_version, "RETURN 5 AS num", %{},
                 recv_timeout: 5000
               )
    end
  end

  describe "run_statement/7" do
    test "(no params, no metadata, no options)", %{port: port, bolt_version: bolt_version} do
      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 AS num")
    end

    test "(params, no metadata, no options)", %{port: port, bolt_version: bolt_version} do
      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN $num AS num", %{
                 num: 14
               })
    end

    test "(no params, metadata, no options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN 1 AS num",
                 %{},
                 metadata
               )
    end

    test "(params, metadata, no options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN $num AS num",
                 %{num: 14},
                 metadata
               )
    end

    test "(no params, no metadata, options)", %{port: port, bolt_version: bolt_version} do
      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN 1 AS num",
                 %{},
                 %{},
                 recv_timeout: 5000
               )
    end

    test "(params, no metadata, options)", %{port: port, bolt_version: bolt_version} do
      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN $num AS num",
                 %{num: 14},
                 %{},
                 recv_timeout: 5000
               )
    end

    test "(no params, metadata, options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN 1 AS num",
                 %{},
                 metadata,
                 recv_timeout: 5000
               )
    end

    test "(params, metadata, options)", %{port: port, bolt_version: bolt_version} do
      {:ok, metadata} = Metadata.new(%{tx_timeout: 1_000})

      assert [success: _, record: _, success: _] =
               BoltProtocol.run_statement(
                 :gen_tcp,
                 port,
                 bolt_version,
                 "RETURN $num AS num",
                 %{num: 14},
                 metadata,
                 recv_timeout: 5000
               )
    end
  end

  describe "transactions" do
    test "Successful committed transaction (begin + run_statement + commit)", %{
      port: port,
      bolt_version: bolt_version
    } do
      {:ok, _} = BoltProtocol.begin(:gen_tcp, port, bolt_version)

      [success: _, record: _, success: _] =
        BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 AS num")

      assert {:ok, _} = BoltProtocol.commit(:gen_tcp, port, bolt_version)
    end

    test "Successful rollbacked transaction (begin + run_statement + rollback)", %{
      port: port,
      bolt_version: bolt_version
    } do
      {:ok, _} = BoltProtocol.begin(:gen_tcp, port, bolt_version)

      [success: _, record: _, success: _] =
        BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETURN 1 AS num")

      assert :ok = BoltProtocol.rollback(:gen_tcp, port, bolt_version)
    end

    test "If an error occurs during transaction, ROLLBACK is performed at server-level", %{
      port: port,
      bolt_version: bolt_version
    } do
      {:ok, _} = BoltProtocol.begin(:gen_tcp, port, bolt_version)

      [success: _, record: _, success: _] =
        BoltProtocol.run_statement(
          :gen_tcp,
          port,
          bolt_version,
          "CREATE (t:Test {value: 555}) RETURN t"
        )

      %Bolt.Sips.Internals.Error{} =
        BoltProtocol.run_statement(:gen_tcp, port, bolt_version, "RETRN 1 AS num")

      assert :ok = BoltProtocol.reset(:gen_tcp, port, bolt_version)

      [success: _, record: [0], success: _] =
        BoltProtocol.run_statement(
          :gen_tcp,
          port,
          bolt_version,
          "MATCH (t:Test {value: 555}) RETURN COUNT(t) AS num_node"
        )
    end
  end
end
