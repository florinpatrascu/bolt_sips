defmodule One.Test do
  use ExUnit.Case
  doctest Bolt.Sips

  # alias Bolt.Sips.{Success, Error, Response}
  # alias Bolt.Sips.Types.{Node, Relationship, UnboundRelationship, Path}

  setup_all do
    {:ok, [conn: Bolt.Sips.conn]}
  end

  test "temporary placeholder for focused tests during development/debugging" do
    assert 2 == 1+1
  end
end

