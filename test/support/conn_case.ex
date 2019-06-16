defmodule Bolt.Sips.ConnCase do
  use ExUnit.CaseTemplate

  setup_all do
    Bolt.Sips.start_link(Application.get_env(:bolt_sips, Bolt))
    conn = Bolt.Sips.conn()

    on_exit(fn ->
      Bolt.Sips.Test.Support.Database.clear(conn)
    end)

    {:ok, conn: conn}
  end
end
