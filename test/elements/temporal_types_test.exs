defmodule BoltSips.Element.TemporalTypesTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Response

  @date [
    success: %{"fields" => ["d"], "result_available_after" => 1},
    record: [[sig: 68, fields: [17167]]],
    success: %{"result_consumed_after" => 3, "type" => "r"}
  ]

  @time [
    success: %{"fields" => ["t"], "result_available_after" => 1},
    record: [[sig: 84, fields: [45_930_250_000_000, 3600]]],
    success: %{"result_consumed_after" => 5, "type" => "r"}
  ]

  @local_time [
    success: %{"fields" => ["t"], "result_available_after" => 0},
    record: [[sig: 116, fields: [45_930_250_000_000]]],
    success: %{"result_consumed_after" => 1, "type" => "r"}
  ]

  @duration [
    success: %{"fields" => ["d"], "result_available_after" => 1},
    record: [[sig: 69, fields: [15, 34, 54, 5550]]],
    success: %{"result_consumed_after" => 0, "type" => "r"}
  ]

  @local_datetime [
    success: %{"fields" => ["d"], "result_available_after" => 6},
    record: [[sig: 100, fields: [1_522_931_640, 543_000_000]]],
    success: %{"result_consumed_after" => 0, "type" => "r"}
  ]

  @datetime_with_zone_offset [
    success: %{"fields" => ["d"], "result_available_after" => 6},
    record: [[sig: 70, fields: [1_522_931_663, 543_000_000, 3600]]],
    success: %{"result_consumed_after" => 0, "type" => "r"}
  ]

  @datetime_with_zone_id [
    success: %{"fields" => ["d"], "result_available_after" => 11},
    record: [[sig: 102, fields: [1_522_931_663, 543_000_000, "Europe/Berlin"]]],
    success: %{"result_consumed_after" => 1, "type" => "r"}
  ]

  test "success with a DATE" do
    assert [%{"d" => ~D[2017-01-01]}] == Response.transform(@date)
  end

  test "success with a TIME" do
    assert [
             %{
               "t" => %Bolt.Sips.Types.TimeWithTZOffset{
                 time: ~T[12:45:30.250000],
                 timezone_offset: 3600
               }
             }
           ] == Response.transform(@time)
  end

  test "success with a LOCALTIME" do
    assert [%{"t" => ~T[12:45:30.250000]}] == Response.transform(@local_time)
  end

  test "success with a DURATION" do
    assert [
             %{
               "d" => %Bolt.Sips.Types.Duration{
                 days: 34,
                 hours: 0,
                 minutes: 0,
                 nanoseconds: 5550,
                 seconds: 54,
                 weeks: 0,
                 months: 3,
                 years: 1
               }
             }
           ] == Response.transform(@duration)
  end

  test "success with a LOCAL DATETIME" do
    assert [%{"d" => ~N[2018-04-05 12:34:00.543]}] == Response.transform(@local_datetime)
  end

  test "success with a DATETIME WITH ZONE OFFSET" do
    # assert  == Response.transform(@duration)

    assert [
             %{
               "d" => %Bolt.Sips.Types.DateTimeWithTZOffset{
                 naive_datetime: ~N[2018-04-05 12:34:23.543],
                 timezone_offset: 3600
               }
             }
           ] == Response.transform(@datetime_with_zone_offset)
  end

  test "success with a DATETIME WITH ZONE ID" do
    dt = Bolt.Sips.TypesHelper.datetime_with_micro(~N[2018-04-05 12:34:23.543], "Europe/Berlin")
    assert [%{"d" => dt}] == Response.transform(@datetime_with_zone_id)
  end
end
