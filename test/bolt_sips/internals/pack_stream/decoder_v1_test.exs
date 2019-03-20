defmodule Bolt.Sips.Internals.PackStream.DecoderV1Test do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream
  alias Bolt.Sips.Internals.PackStream.DecoderV1

  test "decodes null" do
    assert DecoderV1.decode(<<0xC0>>, 1) == [nil]
  end

  test "decodes boolean" do
    assert DecoderV1.decode(<<0xC3>>, 1) == [true]
    assert DecoderV1.decode(<<0xC2>>, 1) == [false]
  end

  test "decodes floats" do
    positive = <<0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>
    negative = <<0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>

    assert DecoderV1.decode(positive, 1) == [1.1]
    assert DecoderV1.decode(negative, 1) == [-1.1]
  end

  test "decodes strings" do
    longstr =
      <<0xD0, 0x1A, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D,
        0x6E, 0x6F, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A>>

    specialcharstr =
      <<0xD0, 0x18, 0x45, 0x6E, 0x20, 0xC3, 0xA5, 0x20, 0x66, 0x6C, 0xC3, 0xB6, 0x74, 0x20, 0xC3,
        0xB6, 0x76, 0x65, 0x72, 0x20, 0xC3, 0xA4, 0x6E, 0x67, 0x65, 0x6E>>

    assert DecoderV1.decode(<<0x80>>, 1) == [""]
    assert DecoderV1.decode(<<0x81, 0x61>>, 1) == ["a"]
    assert DecoderV1.decode(longstr, 1) == ["abcdefghijklmnopqrstuvwxyz"]
    assert DecoderV1.decode(specialcharstr, 1) == ["En å flöt över ängen"]
  end

  test "decodes lists" do
    assert DecoderV1.decode(<<0x90>>, 1) == [[]]
    assert DecoderV1.decode(<<0x93, 0x01, 0x02, 0x03>>, 1) == [[1, 2, 3]]

    list_8 = <<0xD4, 16::8>> <> (1..16 |> Enum.map(&PackStream.encode(&1, 1)) |> Enum.join())
    assert DecoderV1.decode(list_8, 1) == [1..16 |> Enum.to_list()]

    list_16 = <<0xD5, 256::16>> <> (1..256 |> Enum.map(&PackStream.encode(&1, 1)) |> Enum.join())
    assert DecoderV1.decode(list_16, 1) == [1..256 |> Enum.to_list()]

    list_32 =
      <<0xD6, 66_000::32>> <> (1..66_000 |> Enum.map(&PackStream.encode(&1, 1)) |> Enum.join())

    assert DecoderV1.decode(list_32, 1) == [1..66_000 |> Enum.to_list()]

    ending_0_list = <<0x93, 0x91, 0x1, 0x92, 0x2, 0x0, 0x0>>
    assert DecoderV1.decode(ending_0_list, 1) == [[[1], [2, 0], 0]]
  end

  test "decodes maps" do
    assert DecoderV1.decode(<<0xA0>>, 1) == [%{}]
    assert DecoderV1.decode(<<0xA1, 0x81, 0x61, 0x01>>, 1) == [%{"a" => 1}]
    assert DecoderV1.decode(<<0xAB, 0x81, 0x61, 0x01>>, 1) == [%{"a" => 1}]

    map_8 =
      <<0xD8, 16::8>> <>
        (1..16
         |> Enum.map(fn i -> PackStream.encode("#{i}", 1) <> <<1>> end)
         |> Enum.join())

    assert DecoderV1.decode(map_8, 1) |> List.first() |> map_size == 16

    map_16 =
      <<0xD9, 256::16>> <>
        (1..256
         |> Enum.map(fn i -> PackStream.encode("#{i}", 1) <> <<1>> end)
         |> Enum.join())

    assert DecoderV1.decode(map_16, 1) |> List.first() |> map_size == 256

    map_32 =
      <<0xDA, 66_000::32>> <>
        (1..66_000
         |> Enum.map(fn i -> PackStream.encode("#{i}", 1) <> <<1>> end)
         |> Enum.join())

    assert DecoderV1.decode(map_32, 1) |> List.first() |> map_size == 66_000
  end

  test "decodes integers" do
    assert DecoderV1.decode(<<0x2A>>, 1) == [42]
    assert DecoderV1.decode(<<0xC8, 0x2A>>, 1) == [42]
    assert DecoderV1.decode(<<0xC9, 0, 0x2A>>, 1) == [42]
    assert DecoderV1.decode(<<0xCA, 0, 0, 0, 0x2A>>, 1) == [42]
    assert DecoderV1.decode(<<0xCB, 0, 0, 0, 0, 0, 0, 0, 0x2A>>, 1) == [42]
  end

  test "decodes negative integers" do
    assert DecoderV1.decode(<<0xC8, 0xD6>>, 1) == [-42]
  end

  test "decodes Node" do
    node =
      <<0x91, 0xB3, 0x4E, 0x11, 0x91, 0x86, 0x50, 0x65, 0x72, 0x73, 0x6F, 0x6E, 0xA2, 0x84, 0x6E,
        0x61, 0x6D, 0x65, 0xD0, 0x10, 0x50, 0x61, 0x74, 0x72, 0x69, 0x63, 0x6B, 0x20, 0x52, 0x6F,
        0x74, 0x68, 0x66, 0x75, 0x73, 0x73, 0x89, 0x62, 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70,
        0x73, 0xC3>>

    assert [
             [
               %Bolt.Sips.Types.Node{
                 id: 17,
                 labels: ["Person"],
                 properties: %{"bolt_sips" => true, "name" => "Patrick Rothfuss"}
               }
             ]
           ] == DecoderV1.decode(node, 1)
  end

  test "decodes Relationship" do
    rel = <<0x91, 0xB5, 0x52, 0x50, 0x46, 0x43, 0x85, 0x57, 0x52, 0x4F, 0x54, 0x45, 0xA0>>

    assert [
             [
               %Bolt.Sips.Types.Relationship{
                 end: 67,
                 id: 80,
                 properties: %{},
                 start: 70,
                 type: "WROTE"
               }
             ]
           ] = DecoderV1.decode(rel, 1)
  end

  test "decodes path" do
    path =
      <<0x91, 0xB3, 0x50, 0x92, 0xB3, 0x4E, 0x30, 0x90, 0xA2, 0x84, 0x6E, 0x61, 0x6D, 0x65, 0x85,
        0x41, 0x6C, 0x69, 0x63, 0x65, 0x89, 0x62, 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70, 0x73,
        0xC3, 0xB3, 0x4E, 0x38, 0x90, 0xA2, 0x84, 0x6E, 0x61, 0x6D, 0x65, 0x83, 0x42, 0x6F, 0x62,
        0x89, 0x62, 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70, 0x73, 0xC3, 0x91, 0xB3, 0x72, 0x13,
        0x85, 0x4B, 0x4E, 0x4F, 0x57, 0x53, 0xA0, 0x92, 0x1, 0x1>>

    [
      [
        %Bolt.Sips.Types.Path{
          nodes: [
            %Bolt.Sips.Types.Node{
              id: 48,
              labels: [],
              properties: %{"bolt_sips" => true, "name" => "Alice"}
            },
            %Bolt.Sips.Types.Node{
              id: 56,
              labels: [],
              properties: %{"bolt_sips" => true, "name" => "Bob"}
            }
          ],
          relationships: [
            %Bolt.Sips.Types.UnboundRelationship{
              end: nil,
              id: 19,
              properties: %{},
              start: nil,
              type: "KNOWS"
            }
          ],
          sequence: [1, 1]
        }
      ]
    ] = DecoderV1.decode(path, 1)
  end
end
