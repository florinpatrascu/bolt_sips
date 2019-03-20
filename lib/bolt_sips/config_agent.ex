defmodule Bolt.Sips.ConfigAgent do
  @moduledoc false
  # just hold the user config and offer some utility for accessing it

  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> %{opts: opts} end, name: __MODULE__)
  end

  def get_config do
    Agent.get(__MODULE__, fn state -> state[:opts] end)
  end
end
