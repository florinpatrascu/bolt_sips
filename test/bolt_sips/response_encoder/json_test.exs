defmodule Bolt.Sips.ResponseEncode.JsonTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Types.{
    DateTimeWithTZOffset,
    TimeWithTZOffset,
    Duration,
    Point,
    Node,
    Relationship,
    UnboundRelationship,
    Path
  }

  alias Bolt.Sips.ResponseEncoder.Json

  defmodule TestStruct do
    defstruct [:id, :name]
  end

  test "Encode a DateTimeWithTZOffset" do
    dt = DateTimeWithTZOffset.create(~N[2019-03-05 12:34:56], 3600)
    assert "2019-03-05T12:34:56+01:00" == Json.encode(dt)
  end

  test "Encode a TimeWithTZOffset" do
    t = TimeWithTZOffset.create(~T[12:34:56], 7200)
    assert "12:34:56+02:00" == Json.encode(t)
  end

  test "Encode a Duration" do
    d = %Duration{
      days: 0,
      hours: 0,
      minutes: 54,
      months: 12,
      nanoseconds: 0,
      seconds: 65,
      weeks: 0,
      years: 1
    }

    assert "P1Y12MT54M65.0S" == Json.encode(d)
  end

  test "Encode a Point" do
    p = Point.create(:cartesian, 50, 60.5)
    assert %{crs: "cartesian", x: 50.0, y: 60.5} == Json.encode(p)
  end

  test "Encode a Node" do
    n = %Node{
      id: 69,
      labels: ["Test"],
      properties: %{
        "uuid" => 12345,
        "name" => "First node"
      }
    }

    expected = %{id: 69, labels: ["Test"], properties: %{"name" => "First node", "uuid" => 12345}}
    assert expected == Json.encode(n)
  end

  test "Encode a Relationship" do
    r = %Relationship{
      end: 30,
      id: 5,
      properties: %{
        is_valid: true
      },
      start: 69,
      type: "UPDATED_TO"
    }

    expected = %{end: 30, id: 5, properties: %{is_valid: true}, start: 69, type: "UPDATED_TO"}
    assert expected == Json.encode(r)
  end

  test "Encode a UnboundRelationship" do
    r = %UnboundRelationship{
      end: 30,
      id: 5,
      properties: %{
        is_valid: true
      },
      start: 69,
      type: "UPDATED_TO"
    }

    expected = %{end: 30, id: 5, properties: %{is_valid: true}, start: 69, type: "UPDATED_TO"}
    assert expected == Json.encode(r)
  end

  test "Encode a Path" do
    p = %Path{
      nodes: [
        %Node{
          id: 56,
          labels: [],
          properties: %{"bolt_sips" => true, "name" => "Alice"}
        },
        %Node{
          id: 57,
          labels: [],
          properties: %{"bolt_sips" => true, "name" => "Bob"}
        }
      ],
      relationships: [
        %UnboundRelationship{
          end: nil,
          id: 58,
          properties: %{},
          start: nil,
          type: "KNOWS"
        }
      ],
      sequence: [1, 1]
    }

    expected = %{
      nodes: [
        %{id: 56, labels: [], properties: %{"bolt_sips" => true, "name" => "Alice"}},
        %{id: 57, labels: [], properties: %{"bolt_sips" => true, "name" => "Bob"}}
      ],
      relationships: [%{end: nil, id: 58, properties: %{}, start: nil, type: "KNOWS"}],
      sequence: [1, 1]
    }

    assert expected == Json.encode(p)
  end

  test "Encode user-defined struct" do
    s = %TestStruct{id: 1, name: "test"}
    expected = %{id: 1, name: "test"}
    assert expected == Json.encode(s)
  end

  test "Encode Nested types" do
    nested = [
      %{
        "rel" => %Relationship{
          end: 30,
          id: 5,
          properties: %{
            "created" => %DateTimeWithTZOffset{
              naive_datetime: ~N[2016-05-24 13:26:08.543],
              timezone_offset: 7200
            }
          },
          start: 69,
          type: "UPDATED_TO_"
        },
        "t1" => %Node{
          id: 69,
          labels: ["Test"],
          properties: %{
            "created" => %DateTimeWithTZOffset{
              naive_datetime: ~N[2016-05-24 13:26:08.543],
              timezone_offset: 7200
            },
            "uuid" => 12345
          }
        },
        "t2" => %Node{
          id: 30,
          labels: ["Test"],
          properties: %{"uuid" => 6789}
        }
      }
    ]

    expected = [
      %{
        "rel" => %{
          end: 30,
          id: 5,
          properties: %{"created" => "2016-05-24T13:26:08.543+02:00"},
          start: 69,
          type: "UPDATED_TO_"
        },
        "t1" => %{
          id: 69,
          labels: ["Test"],
          properties: %{
            "created" => "2016-05-24T13:26:08.543+02:00",
            "uuid" => 12345
          }
        },
        "t2" => %{
          id: 30,
          labels: ["Test"],
          properties: %{"uuid" => 6789}
        }
      }
    ]

    assert expected == Json.encode(nested)
  end
end
