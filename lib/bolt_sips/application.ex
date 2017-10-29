defmodule Bolt.Sips.Application do
  @moduledoc false

  use Application

  alias Bolt.Sips

  def start(_, start_args) do
    Sips.start_link(start_args)
  end

  def stop(_state) do
    :ok
  end
end
