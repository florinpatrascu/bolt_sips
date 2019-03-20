defmodule Bolt.Sips.Test.Support.Database do
  def clear(conn) do
    Bolt.Sips.query!(conn, "MATCH (n) DETACH DELETE n")
  end
end
