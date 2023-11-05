defmodule Bolt.Sips.ConnectionTest do
  use ExUnit.Case, async: false

  alias Bolt.Sips.Connection

  @opts Bolt.Sips.TestHelper.opts()

  @tag core: true
  test "connect/1 - disconnect/1 successful" do
    assert {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert is_bitstring(server_version)
    assert is_float(bolt_version)
    assert :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag core: true
  test "checkout/1 successful" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert is_bitstring(server_version)
    assert is_float(bolt_version)
    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkout(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag core: true
  test "checkin/1 successful" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert is_bitstring(server_version)
    assert is_float(bolt_version)

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag bolt_version: "1.0"
  test "connect/1 successful with bolt version 1.0" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert server_version == "Neo4j/3.4.0"
    assert bolt_version == 1.0

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag bolt_version: "2.0"
  test "connect/1 successful with bolt version 2.0" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert server_version == "Neo4j/3.4.0"
    assert bolt_version == 2.0

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag bolt_version: "3.0"
  test "connect/1 successful with bolt version 3.0" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert server_version == "Neo4j/4.4.26"
    assert bolt_version == 3.0

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag bolt_version: "4.0"
  test "connect/1 successful with bolt version 4.0" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert server_version == "Neo4j/3.4.0"
    assert bolt_version == 4.0

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag bolt_version: "5.0"
  test "connect/1 successful with bolt version 5.0" do
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(@opts)
    assert server_version == "Neo4j/3.4.0"
    assert bolt_version == 5.0

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

  @tag bolt_version: "5.0"
  test "connect/1 successful with specific bolt version" do
    opts = [versions: [5.3]] ++ @opts
    {:ok, %Connection{client: _, bolt_version: bolt_version, server_version: server_version} = conn_data} =
      Connection.connect(opts)
    assert server_version == "Neo4j/3.4.0"
    assert bolt_version == 5.3

    assert {:ok, %Connection{client: _, bolt_version: _} = conn_data} =
      Connection.checkin(conn_data)

    :ok = Connection.disconnect(:stop, conn_data)
  end

end
