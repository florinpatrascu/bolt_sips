defmodule BoltSips.Element.SpatialTypesTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Response

  @cartesian_2d_point [
    success: %{"fields" => ["p"], "result_available_after" => 0},
    record: [[sig: 88, fields: [7203, 40.0, 45.0]]],
    success: %{"result_consumed_after" => 1, "type" => "r"}
  ]

  @geo_2d_point [
    success: %{"fields" => ["p"], "result_available_after" => 16},
    record: [[sig: 88, fields: [4326, 40.0, 45.0]]],
    success: %{"result_consumed_after" => 0, "type" => "r"}
  ]

  @cartesian_3d_point [
    success: %{"fields" => ["p"], "result_available_after" => 19},
    record: [[sig: 89, fields: [9157, 45.0, 45.0, 150.0]]],
    success: %{"result_consumed_after" => 2, "type" => "r"}
  ]

  @geo_3d_point [
    success: %{"fields" => ["p"], "result_available_after" => 18},
    record: [[sig: 89, fields: [4979, 45.0, 45.0, 150.0]]],
    success: %{"result_consumed_after" => 1, "type" => "r"}
  ]

  test "success with a CARTESIAN 2D POINT" do
    assert [
             %{
               "p" => %Bolt.Sips.Types.Point{
                 crs: "cartesian",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 7203,
                 x: 40.0,
                 y: 45.0,
                 z: nil
               }
             }
           ] == Response.transform(@cartesian_2d_point)
  end

  test "success with a GEOGRAPHIC 2D POINT" do
    assert [
             %{
               "p" => %Bolt.Sips.Types.Point{
                 crs: "wgs-84",
                 height: nil,
                 latitude: 45.0,
                 longitude: 40.0,
                 srid: 4326,
                 x: 40.0,
                 y: 45.0,
                 z: nil
               }
             }
           ] == Response.transform(@geo_2d_point)
  end

  test "success with a CARTESIAN 3D POINT" do
    assert [
             %{
               "p" => %Bolt.Sips.Types.Point{
                 crs: "cartesian-3d",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 9157,
                 x: 45.0,
                 y: 45.0,
                 z: 150.0
               }
             }
           ] == Response.transform(@cartesian_3d_point)
  end

  test "success with a GEOGRAPHIC 3D POINT" do
    assert [
             %{
               "p" => %Bolt.Sips.Types.Point{
                 crs: "wgs-84-3d",
                 height: 150.0,
                 latitude: 45.0,
                 longitude: 45.0,
                 srid: 4979,
                 x: 45.0,
                 y: 45.0,
                 z: 150.0
               }
             }
           ] == Response.transform(@geo_3d_point)
  end
end
