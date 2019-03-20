defmodule Bolt.Sips.Internals.PackStream.EncoderHelperTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.EncoderHelper
  alias Bolt.Sips.Internals.PackStreamError

  describe "call_encode/3" do
    test "successfull when call with existing bolt_version" do
      assert <<_::binary>> = EncoderHelper.call_encode(:atom, true, 1)
    end

    test "successfull when call with superior bolt_version" do
      assert <<_::binary>> = EncoderHelper.call_encode(:atom, true, 4)
    end

    test "fails when call with bolt_version <= 0" do
      assert_raise PackStreamError, fn ->
        EncoderHelper.call_encode(:atom, true, -1)
      end
    end

    test "fails when call with a non integer bolt_version" do
      assert_raise PackStreamError, fn ->
        EncoderHelper.call_encode(:atom, true, :invalid)
      end
    end

    test "fails when call with a non supported data type" do
      assert_raise PackStreamError, fn ->
        EncoderHelper.call_encode(:non_supported, true, 1)
      end
    end
  end
end
