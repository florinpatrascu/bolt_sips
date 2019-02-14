defmodule Bolt.Sips.ConnCase do
  use ExUnit.CaseTemplate

  setup_all do
    conn = Bolt.Sips.conn()

    {:ok, conn: conn}
  end
end
