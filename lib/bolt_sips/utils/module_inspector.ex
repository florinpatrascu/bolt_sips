defmodule Bolt.Sips.Utils.ModuleInspector do
  def match_modules(hint) do
    Enum.map(get_modules(), &Atom.to_string/1)
    |> :lists.usort()
    |> Enum.drop_while(&(not String.starts_with?(&1, hint)))
    |> Enum.take_while(&String.starts_with?(&1, hint))
  end

  def get_modules() do
    loaded_applications()
    {:ok, modules} = :application.get_key(BoltSips.Mixfile.project()[:app], :modules)
    modules
  end

  defp loaded_applications do
    # If we invoke :application.loaded_applications/0,
    # it can error if we don't call safe_fixtable before.
    # Since in both cases we are reaching over the
    # application controller internals, we choose to match
    # for performance.
    :ets.match(:ac_tab, {{:loaded, :"$1"}, :_})
  end
end
