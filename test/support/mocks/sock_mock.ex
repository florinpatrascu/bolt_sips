defmodule Bolt.Sips.Mocks.SockMock do
  def loop(state) do
    receive do
      {_from, :push, value} ->
        loop([value | state])

      {from, :pop} ->
        [h | t] = state
        send(from, {:reply, h})
        loop(t)
    end
    loop(state)
  end
  def start_link(state) do
      spawn_link( __MODULE__ , :loop, [init(state)])
  end

  def init(state), do: state

  def push(pid, value) do
      send(pid, {self(), :push, value})
      :ok
  end

  def pop(pid) do
      send(pid, {self(), :pop})
      receive do
          {:reply, value} -> value
      end
  end

  def recv(pid, _length, _timeout) do
    message = pop(pid)
    {:ok, message}
  end
end
