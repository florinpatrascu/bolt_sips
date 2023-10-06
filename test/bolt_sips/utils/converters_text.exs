defmodule ConvertersTest do
  use ExUnit.Case
  alias Bolt.Sips.Utils.Converters

  describe "to_float/1" do
    @tag core: true
    test "when the value is a float, it should return the float" do
      assert Converters.to_float(3.14) == 3.14
    end

    @tag core: true
    test "when the value is an integer, it should return the integer as a float" do
      assert Converters.to_float(42) == 42.0
    end

    @tag core: true
    test "when the value is a string representation of a float, it should return the float" do
      assert Converters.to_float("3.14") == 3.14
    end

    @tag core: true
    test "when the value is a string representation of an integer, it should return the integer as a float" do
      assert Converters.to_float("42") == 42.0
    end

    @tag core: true
    test "when the value is a string representation of neither float nor integer, it should raise an error" do
      assert {:error, "Could not convert to float"} == Converters.to_float("not_a_number")
    end

    @tag core: true
    test "when the value is neither float nor integer, it should raise an error" do
      assert {:error, "Could not convert to float"} == Converters.to_float(:not_a_number)
    end
  end
end
