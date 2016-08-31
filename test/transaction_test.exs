defmodule Transaction.Test do
  use ExUnit.Case, async: true

  test "execute statements in an open transaction" do
    conn = Bolt.Sips.begin(Bolt.Sips.conn)
    book = Bolt.Sips.query!(conn, "CREATE (b:Book {title: \"The Game Of Trolls\"}) return b") |> List.first
    assert %{"b" => g_o_t} = book
    assert g_o_t.properties["title"] == "The Game Of Trolls"
    Bolt.Sips.rollback(conn)
    books = Bolt.Sips.query!(conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")
    assert length(books) == 0
  end

  ###
  ### NOTE:
  ###
  ### The labels used in these examples MUST be unique across all tests!
  ### These tests depend on being able to expect that a node either exists
  ### or does not, and asynchronous testing with the same names will cause
  ### random cases where the underlying state changes.
  ###

  test "rollback statements in an open transaction" do
    try do
      # In case there's already a copy in our DB, count them...
      {:ok, [result]} = Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactRollback) RETURN count(x)")
      original_count = result["count(x)"]

      conn = Bolt.Sips.begin(Bolt.Sips.conn)

      book = Bolt.Sips.query(conn, "CREATE (x:XactRollback {title:\"The Game Of Trolls\"}) return x")
      assert {:ok, [row]} = book
      assert row["x"].properties["title"] == "The Game Of Trolls"

      # Original connection (outside the transaction) should not see this node.
      {:ok, [result]} = Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactRollback) RETURN count(x)")
      assert result["count(x)"] == original_count,
          "Main connection should not be able to see transactional change"

      Bolt.Sips.rollback(conn)
      # The open connection should not see this node committed after rollback.
      {:ok, [result]} = Bolt.Sips.query(conn, "MATCH (x:XactRollback) RETURN count(x)")
      assert result["count(x)"] == original_count

      # Original connection should still not see this node committed.
      {:ok, [result]} = Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactRollback) RETURN count(x)")
      assert result["count(x)"] == original_count
    after
      # Delete all XactRollback nodes in case the rollback() didn't work!
      Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactRollback) DETACH DELETE x")
    end
  end

  test "commit statements in an open transaction" do
    try do
      conn = Bolt.Sips.begin(Bolt.Sips.conn)
      book = Bolt.Sips.query(conn, "CREATE (x:XactCommit {foo: 'bar'}) return x")
      assert {:ok, [row]} = book
      assert row["x"].properties["foo"] == "bar"

      # Main connection should not see this new node.
      {:ok, results} = Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactCommit) RETURN x")
      assert is_list(results)
      assert Enum.count(results) == 0,
          "Main connection should not be able to see transactional changes"

      # Now, commit...
      Bolt.Sips.commit(conn)

      # And we should see it now with the main connection.
      {:ok, [%{"x" => node}]} = Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactCommit) RETURN x")
      assert node.labels == ["XactCommit"]
      assert node.properties["foo"] == "bar"

    after
      # Delete any XactCommit nodes that were succesfully committed!
      Bolt.Sips.query(Bolt.Sips.conn, "MATCH (x:XactCommit) DETACH DELETE x")
    end
  end
end
