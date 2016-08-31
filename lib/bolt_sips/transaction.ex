defmodule Bolt.Sips.Transaction do
  @moduledoc """
  This module is the main implementation for running Cypher commands using
  transactions.

  Example:

  ```elixir
  test "execute statements in an open transaction" do
    conn = Bolt.Sips.begin(Bolt.Sips.conn)
    book = Bolt.Sips.query!(conn, "CREATE (b:Book {title: \"The Game Of Trolls\"}) return b") |> List.first
    assert %{"b" => g_o_t} = book
    assert g_o_t.properties["title"] == "The Game Of Trolls"
    Bolt.Sips.rollback(conn)
    books = Bolt.Sips.query!(conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")
    assert length(books) == 0
  end
  ```
  """

  alias Bolt.Sips.{Success, Connection}

  @doc """
  begin a new transaction.
  """
  @spec begin(Bolt.Sips.Connection) :: []
  def begin(conn) do
    Connection.send(conn, "BEGIN")
    conn
  end

  @doc """
  given that you have an open transaction, you can send a rollback request.
  The server will rollback the transaction. Any further statements trying to run
  in this transaction will fail immediately.
  """
  @spec rollback(Bolt.Sips.Connection) :: []
  def rollback(conn) do
    Connection.send(conn, "ROLLBACK")
  end

  @doc """
  given you have an open transaction, you can use this to send a commit request
  """
  @spec commit(Bolt.Sips.Connection) :: []
  def commit(conn) do
    Connection.send(conn, "COMMIT")
  end
end
