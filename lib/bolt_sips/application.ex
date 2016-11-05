defmodule Bolt.Sips.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Bolt.Sips, [Application.get_env(:bolt_sips, Bolt)])
    ]

    opts = [strategy: :one_for_one, name: Bolt.Sips.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
