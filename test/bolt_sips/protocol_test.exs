defmodule Bolt.Sips.ProtocolTest do
  use ExUnit.Case, async: false

  alias Bolt.Sips.Protocol

  test "Happy tests..." do
    {:ok, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} = Protocol.connect([])

    {:ok, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} = Protocol.checkout(conn_data)
    {:ok, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} = Protocol.checkin(conn_data)

    {:ok, :began, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} =
      Protocol.handle_begin([], conn_data)

    {:ok, :rolledback, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} =
      Protocol.handle_rollback([], conn_data)

    {:ok, :began, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} =
      Protocol.handle_begin([], conn_data)

    {:ok, :committed, %Protocol.ConnData{sock: _, bolt_version: _} = conn_data} =
      Protocol.handle_commit([], conn_data)

    :ok = Protocol.disconnect(:stop, conn_data)
  end
end
