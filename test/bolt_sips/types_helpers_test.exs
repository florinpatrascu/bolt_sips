defmodule Bolt.Sips.TypesHelperTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.TypesHelper

  describe "decompose_in_hms/1:" do
    test "Ok if more than a hour" do
      assert {1, 6, 27} = TypesHelper.decompose_in_hms(3987)
    end

    test "Ok if less than a hour" do
      assert {0, 44, 35} = TypesHelper.decompose_in_hms(2675)
    end

    test "Ok if less than a minute" do
      assert {0, 0, 43} = TypesHelper.decompose_in_hms(43)
    end

    test "edge case: 1 hour" do
      assert {1, 0, 0} = TypesHelper.decompose_in_hms(3600)
    end

    test "edge case: 1 minute" do
      assert {0, 1, 0} = TypesHelper.decompose_in_hms(60)
    end
  end

  describe "datetime_with_micro/2:" do
    test "Successful with valid data" do
      expected = %DateTime{
        calendar: Calendar.ISO,
        day: 1,
        hour: 23,
        microsecond: {0, 0},
        minute: 0,
        month: 1,
        second: 7,
        std_offset: 0,
        time_zone: "Europe/Paris",
        utc_offset: 3600,
        year: 2000,
        zone_abbr: "CET"
      }

      assert ^expected = TypesHelper.datetime_with_micro(~N[2000-01-01 23:00:07], "Europe/Paris")
    end

    test "Fails with invalid timezone" do
      assert_raise MatchError, fn ->
        TypesHelper.datetime_with_micro(~N[2000-01-01 23:00:07], "Invalid")
      end
    end
  end

  describe "formated-time_offset/1" do
    test "Valid positive offset" do
      assert "+01:03" == TypesHelper.formated_time_offset(3783)
    end

    test "Valid negative offset" do
      assert "-01:03" == TypesHelper.formated_time_offset(-3783)
    end
  end
end
