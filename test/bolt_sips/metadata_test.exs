defmodule Bolt.Sips.MetadataTest do
  use ExUnit.Case, async: true
  alias Bolt.Sips.Metadata

  @valid_metadata %{
    bookmarks: ["neo4j:bookmark:v1:tx1111"],
    tx_timeout: 5000,
    metadata: %{
      desc: "Not lost in transaction"
    }
  }

  describe "Create new metadata from map:" do
    test "with compelete data" do
      expected = %Metadata{
        bookmarks: ["neo4j:bookmark:v1:tx1111"],
        tx_timeout: 5000,
        metadata: %{
          desc: "Not lost in transaction"
        }
      }

      assert {:ok, result} = Metadata.new(@valid_metadata)

      assert expected == result
    end

    test "return error with invalid keys" do
      data = Map.put(@valid_metadata, :invalid, "invalid")
      assert {:error, _} = Metadata.new(data)
    end

    test "return error with invalid bookmarks" do
      data = Map.put(@valid_metadata, :bookmarks, "invalid")
      assert {:error, _} = Metadata.new(data)
    end

    test "return nil with empty bookmarks list" do
      data = Map.put(@valid_metadata, :bookmarks, [])

      expected = %Metadata{
        bookmarks: nil,
        tx_timeout: data.tx_timeout,
        metadata: data.metadata
      }

      assert {:ok, result} = Metadata.new(data)
      assert expected == result
    end

    test "return error with invalid timeout" do
      data = Map.put(@valid_metadata, :tx_timeout, -12)
      assert {:error, _} = Metadata.new(data)
    end

    test "return error with invalid metadata" do
      data = Map.put(@valid_metadata, :metadata, "invalid")
      assert {:error, _} = Metadata.new(data)
    end

    test "return nil with empty metadata map" do
      data = Map.put(@valid_metadata, :metadata, %{})

      expected = %Metadata{
        bookmarks: data.bookmarks,
        tx_timeout: data.tx_timeout,
        metadata: nil
      }

      assert {:ok, result} = Metadata.new(data)
      assert expected == result
    end
  end

  test "to_map remove nullified data" do
    data = %{
      bookmarks: ["neo4j:bookmark:v1:tx1111"],
      tx_timeout: 5000
    }

    assert {:ok, metadata} = Metadata.new(data)

    assert %Metadata{bookmarks: ["neo4j:bookmark:v1:tx1111"], metadata: nil, tx_timeout: 5000} ==
             metadata

    expected = %{
      bookmarks: ["neo4j:bookmark:v1:tx1111"],
      tx_timeout: 5000
    }

    assert expected == Metadata.to_map(metadata)
  end
end
