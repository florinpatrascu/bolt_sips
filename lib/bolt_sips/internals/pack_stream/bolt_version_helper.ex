defmodule Bolt.Sips.Internals.PackStream.BoltVersionHelper do
  @moduledoc false
  @available_bolt_versions [1, 2]

  @doc """
  List bolt versions.
  Only bolt version that have specific encoding functions are listed.

  """
  @spec available_versions() :: [integer()]
  def available_versions(), do: @available_bolt_versions

  @doc """
  Retrieve previous valid version.
  Return nil if there is no previous version.

  ## Example

      iex> Bolt.Sips.Internals.PackStream.BoltVersionHelper.previous(2)
      1
      iex> Bolt.Sips.Internals.PackStream.BoltVersionHelper.previous(1)
      nil
      iex> Bolt.Sips.Internals.PackStream.BoltVersionHelper.previous(15)
      2
  """
  @spec previous(integer()) :: nil | integer()
  def previous(version) do
    @available_bolt_versions
    |> Enum.take_while(&(&1 < version))
    |> List.last()
  end

  @doc """
  Return the last available bolt version.

  ## Example:

      iex> Bolt.Sips.Internals.PackStream.BoltVersionHelper.last()
      2
  """
  def last() do
    List.last(@available_bolt_versions)
  end
end
