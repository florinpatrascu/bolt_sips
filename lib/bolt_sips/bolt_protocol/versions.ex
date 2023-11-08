defmodule Bolt.Sips.BoltProtocol.Versions do
  @available_bolt_versions [1.0, 2.0, 3.0, 4.0, 4.1, 4.2, 4.3, 4.4, 5.0, 5.1, 5.2, 5.3, 5.4]

  def available_versions() do
    @available_bolt_versions
  end

  def latest_versions() do
    ((available_versions() |> Enum.sort(&>=/2) |> Enum.into([])) ++ [0, 0, 0]) |> Enum.take(4)
  end

  def to_bytes(version) when is_float(version) do
    [major | [minor]] = version |> Float.to_string() |> String.split(".") |> Enum.map(&String.to_integer/1)
    <<0,0>> <> <<minor, major>>
  end

  def to_bytes(version) when is_integer(version) do
    to_bytes(version + 0.0)
  end
end
