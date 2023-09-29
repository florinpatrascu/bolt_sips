defmodule Bolt.Sips.BoltProtocol.Versions do
  alias Bolt.Sips.Utils.ModuleInspector

  @spec available_versions() :: [float]
  def available_versions() do
    # Obtén la lista de módulos en el namespace BoltProtocol.
    module_names = ModuleInspector.match_modules("Elixir.Bolt.Sips.BoltProtocol.RequestMessage")

    available_versions =
      module_names
      |> Enum.map(&String.split(&1, "."))
      |> Enum.map(fn [_,_, _, _, _, version | _] -> version end)
      |> Enum.map(&String.replace(&1, ~r/^V/, ""))
      |> Enum.map(&String.replace(&1, "_", "."))
      |> Enum.map(&Float.parse/1)
      |> Enum.map(fn {number, _} -> number end)
      |> Enum.sort(fn a, b -> a >= b end)

    case available_versions do
      [] -> [0.0]
      _ -> available_versions
    end
  end

  def latest_versions() do
    ((available_versions() |> Enum.into([])) ++ [0, 0, 0]) |> Enum.take(4) |> Enum.sort(&>=/2)
  end

  def to_bytes(version) when is_float(version) do
    {integer, decimal} = {trunc(version), version - trunc(version) |> Float.ceil |> trunc}
    <<0,0>> <> <<decimal, integer>>
  end

  def to_bytes(version) when is_integer(version) do
    to_bytes(version + 0.0)
  end
end
