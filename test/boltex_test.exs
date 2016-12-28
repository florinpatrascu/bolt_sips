defmodule Boltex.Test do
  use ExUnit.Case
  doctest Bolt.Sips

  setup do
    config = Application.get_env(:bolt_sips, Bolt)
    auth =
      if basic_auth = config[:basic_auth] do
        {basic_auth[:username], basic_auth[:password]}
      else
        nil
      end

    {:ok, p} = :gen_tcp.connect(config[:hostname], config[:port],
                          [active: false, mode: :binary, packet: :raw])

    :ok      = Boltex.Bolt.handshake :gen_tcp, p
    :ok      = Boltex.Bolt.init :gen_tcp, p, auth
    {:ok, [pid: p]}
  end

  test "receiving an error", context do
    p = context[:pid]
    r = Boltex.Bolt.run_statement(:gen_tcp, p, "match (p:Person) return p limited 1")

    {:error, error} = Bolt.Sips.Error.new(r)
    assert error.code == "Neo.ClientError.Statement.SyntaxError"
  end

  test "numeric values in the response", context do
    r = Boltex.Bolt.run_statement(:gen_tcp, context[:pid], "RETURN 10 as num")
    assert r == [{:success, %{"fields" => ["num"]}}, {:record, [10]}, {:success, %{"type" => "r"}}]
  end

end
