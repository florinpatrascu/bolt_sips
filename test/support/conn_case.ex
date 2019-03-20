defmodule Bolt.Sips.ConnCase do
  use ExUnit.CaseTemplate

  setup_all do
    conn = Bolt.Sips.conn()

    on_exit(fn ->
      Bolt.Sips.Test.Support.Database.clear(conn)
    end)

    {:ok, conn: conn}
  end
end
