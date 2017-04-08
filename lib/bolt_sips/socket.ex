defmodule Bolt.Sips.Socket do
  @moduledoc """
  A default socket interface used to communicate to a Neo4j instance.

  Any other socket implementing the same interface can be used
  in place of this one. Actually, this module doesn't
  implement the interface on its own, it delegates calls to
  the gen_tcp (http://erlang.org/doc/man/gen_tcp.html)
  and inet (http://erlang.org/doc/man/inet.html) modules. Any of these
  modules doesn't fully implement the required interface,
  hence, both of them must be used.
  """

  @doc "Delegates to :gen_tcp.connect/4"
  defdelegate connect(host, port, opts, timeout), to: :gen_tcp

  @doc "Delegates to :inet.setopts/2"
  defdelegate setopts(sock, opts), to: :inet

  @doc "Delegates to :gen_tcp.send/2"
  defdelegate send(sock, package), to: :gen_tcp

  @doc "Delegates to :gen_tcp.recv/3"
  defdelegate recv(sock, length, timeout), to: :gen_tcp

  @doc "Delegates to :gen_tcp.recv/2"
  defdelegate recv(sock, length), to: :gen_tcp

  @doc "Delegates to :inet.close/1"
  defdelegate close(sock), to: :inet
end
