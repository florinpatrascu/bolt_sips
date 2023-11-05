Logger.configure(level: :debug)
ExUnit.start(capture_log: true, assert_receive_timeout: 500, exclude: [:skip, :bench, :apoc])
Application.ensure_started(:porcelain)

Code.require_file("test_support.exs", __DIR__)

defmodule Bolt.Sips.TestHelper do
  def opts() do
    [
      address: "127.0.0.1",
      auth: [username: "neo4j", password: "BoltSipsPassword"],
      pool_size: 15,
      max_overflow: 3,
      prefix: :default
    ]
  end
  @doc """
   Read an entire file into a string.
   Return a tuple of success and data.
  """
  def read_whole_file(path) do
    case File.read(path) do
      {:ok, file} -> file
      {:error, reason} -> {:error, "Could not open #{path} #{file_error_description(reason)}"}
    end
  end

  @doc """
    Open a file stream, and join the lines into a string.
  """
  def stream_file_join(filename) do
    stream = File.stream!(filename)
    Enum.join(stream)
  end

  defp file_error_description(:enoent), do: "because the file does not exist."
  defp file_error_description(reason), do: "due to #{reason}."
end

#Bolt.Sips.start_link(Application.get_env(:bolt_sips, Bolt))

# I am using the test db for debugging and the line below will clear *everything*
# Bolt.Sips.query(Bolt.Sips.conn, "MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
#
# todo: The tests should cleanup the data they create.

Process.flag(:trap_exit, true)
