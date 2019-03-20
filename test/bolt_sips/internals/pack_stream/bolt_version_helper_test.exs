defmodule Bolt.Sips.Internals.PackStream.HelperTest do
  use ExUnit.Case, async: true

  doctest Bolt.Sips.Internals.PackStream.BoltVersionHelper

  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper

  test "available_bolt_versions/0 returns a list" do
    assert [_ | _] = BoltVersionHelper.available_versions()
  end

  describe "previous/1" do
    test "successfully return the previous version" do
      assert 1 == BoltVersionHelper.previous(2)
      assert 2 == BoltVersionHelper.previous(3)
      assert 2 == BoltVersionHelper.previous(4)
    end

    test "return nil if there is no previous version" do
      assert nil == BoltVersionHelper.previous(1)
    end
  end
end
