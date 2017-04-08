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
    books = Bolt.Sips.query!(Bolt.Sips.conn, "MATCH (b:Book {title: \"The Game Of Trolls\"}) return b")
    assert length(books) == 0
  end
  ```
  """

  @type result :: {:ok, result :: any} | {:error, Exception.t}

  @doc """
  begin a new transaction.
  """
  @spec begin(DBConnection.conn) :: DBConnection.t | {:error, Exception.t}
  def begin(conn) do
    case DBConnection.begin(conn, [pool: Bolt.Sips.config(:pool)]) do
      {:ok, conn, _} ->
        conn
      other ->
        other
    end
  end

  @doc """
  given that you have an open transaction, you can send a rollback request.
  The server will rollback the transaction. Any further statements trying to run
  in this transaction will fail immediately.
  """
  @spec rollback(DBConnection.t) :: result
  defdelegate rollback(conn), to: DBConnection

  @doc """
  given you have an open transaction, you can use this to send a commit request
  """
  @spec commit(DBConnection.t) :: result
  defdelegate commit(conn), to: DBConnection
end
