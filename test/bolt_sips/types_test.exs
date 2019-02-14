defmodule Bolt.Sips.TypesTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Types.{DateTimeWithTZOffset, Duration, TimeWithTZOffset, Point}

  describe "TimeWithTZOffset struct:" do
    test "create/2" do
      expected = %TimeWithTZOffset{time: ~T[20:00:43], timezone_offset: 3600}
      assert ^expected = TimeWithTZOffset.create(~T[20:00:43], 3600)
    end

    test "format_param/1 successful with valid data" do
      t = %TimeWithTZOffset{time: ~T[23:00:07], timezone_offset: 3600}
      assert {:ok, "23:00:07+01:00"} = TimeWithTZOffset.format_param(t)
    end

    test "format_param/1 fails for invalid data" do
      t = %TimeWithTZOffset{time: ~T[23:00:07], timezone_offset: 3600.543}
      assert {:error, ^t} = TimeWithTZOffset.format_param(t)
    end
  end

  describe "DateTimeWithTZOffset struct:" do
    test "create/2" do
      expected = %DateTimeWithTZOffset{
        naive_datetime: ~N[2000-01-01 23:00:07],
        timezone_offset: 3600
      }

      assert ^expected = DateTimeWithTZOffset.create(~N[2000-01-01 23:00:07], 3600)
    end

    test "format_param/1 successful with valid data" do
      t = %DateTimeWithTZOffset{
        naive_datetime: ~N[2000-01-01 23:00:07],
        timezone_offset: 3600
      }

      assert {:ok, "2000-01-01T23:00:07+01:00"} = DateTimeWithTZOffset.format_param(t)
    end

    test "format_param/2 fails for invalid data" do
      # timezone_offset can't be a float
      t = %DateTimeWithTZOffset{
        naive_datetime: ~N[2000-01-01 23:00:07],
        timezone_offset: 3600.43
      }

      assert {:error, ^t} = DateTimeWithTZOffset.format_param(t)
    end
  end

  describe "Duration struct:" do
    test "create/4" do
      expected = %Duration{
        days: 53,
        hours: 0,
        minutes: 2,
        months: 3,
        nanoseconds: 54,
        seconds: 5,
        weeks: 0,
        years: 1
      }

      assert expected == Duration.create(15, 53, 125, 54)
    end

    test "format_param/1 successful with valid data" do
      duration = Duration.create(15, 53, 125, 54)

      assert {:ok, "P1Y3M53DT2M5.54S"} = Duration.format_param(duration)
    end

    test "format_param/1 fails for invalid data" do
      duration = %Duration{
        days: 53.45,
        hours: 0,
        minutes: 2,
        months: 3,
        nanoseconds: 54,
        seconds: 5,
        weeks: 0,
        years: 1
      }

      assert {:error, ^duration} = Duration.format_param(duration)
    end
  end

  describe "Point struct:" do
    test "create/3 succesfully creates a CARTESIAN point 2D" do
      expected = %Point{
        crs: "cartesian",
        srid: 7203,
        latitude: nil,
        longitude: nil,
        height: nil,
        x: 10.0,
        y: 20.0,
        z: nil
      }

      assert expected == Point.create(:cartesian, 10, 20.0)
    end

    test "create/3 succesfully creates a GEOGRAPHIC point 2D" do
      expected = %Point{
        crs: "wgs-84",
        srid: 4326,
        latitude: 20.0,
        longitude: 10.0,
        height: nil,
        x: 10.0,
        y: 20.0,
        z: nil
      }

      assert expected == Point.create(:wgs_84, 10, 20.0)
    end

    test "create/4 succesfully creates a CARTESIAN point 3D" do
      expected = %Point{
        crs: "cartesian-3d",
        srid: 9157,
        latitude: nil,
        longitude: nil,
        height: nil,
        x: 10.0,
        y: 20.0,
        z: 25.43
      }

      assert expected == Point.create(:cartesian, 10, 20.0, 25.43)
    end

    test "create/4 succesfully creates a GEOGRAPHIC point 3D" do
      expected = %Point{
        crs: "wgs-84-3d",
        srid: 4979,
        latitude: 20.0,
        longitude: 10.0,
        height: 25.43,
        x: 10.0,
        y: 20.0,
        z: 25.43
      }

      assert expected == Point.create(:wgs_84, 10, 20.0, 25.43)
    end

    test "format_param/1 successful with valid param" do
      point = Point.create(:wgs_84, 10, 20.0, 25.43)

      expected = %{
        crs: "wgs-84-3d",
        height: 25.43,
        latitude: 20.0,
        longitude: 10.0,
        x: 10.0,
        y: 20.0,
        z: 25.43
      }

      assert {:ok, expected} == Point.format_param(point)
    end

    test "format_param/2 fails for invalid param" do
      point = %Point{
        crs: "wgs-84-3d",
        srid: 4979,
        latitude: 20.0,
        longitude: 10.0,
        height: 25.43,
        x: 10.0,
        y: 20.0,
        z: "invalid"
      }

      assert {:error, ^point} = Point.format_param(point)
    end
  end
end
