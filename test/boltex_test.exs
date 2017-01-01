defmodule Boltex.Test do
  use ExUnit.Case
  doctest Bolt.Sips

  alias Bolt.Sips.Utils
  @socket Bolt.Sips.config(:socket)

  setup do
    config = Utils.default_config
    auth =
      if basic_auth = config[:basic_auth] do
        {basic_auth[:username], basic_auth[:password]}
      else
        nil
      end

    {:ok, p} = @socket.connect(config[:hostname], config[:port],
                          [active: false, mode: :binary, packet: :raw])

    :ok      = Boltex.Bolt.handshake @socket, p
    :ok      = Boltex.Bolt.init @socket, p, auth
    {:ok, [pid: p]}
  end

  test "receiving an error", context do
    p = context[:pid]
    r = Boltex.Bolt.run_statement(@socket, p, "match (p:Person) return p limited 1")

    {:error, error} = Bolt.Sips.Error.new(r)
    assert error.code == "Neo.ClientError.Statement.SyntaxError"
  end

  test "numeric values in the response", context do
    r = Boltex.Bolt.run_statement(@socket, context[:pid], "RETURN 10 as num")
    assert r == [{:success, %{"fields" => ["num"]}}, {:record, [10]}, {:success, %{"type" => "r"}}]
  end

end
