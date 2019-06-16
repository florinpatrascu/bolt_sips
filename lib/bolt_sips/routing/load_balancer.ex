defmodule Bolt.Sips.LoadBalancer do
  @moduledoc """
  a simple load balancer used for selecting a server address from a map. The address is selected based on
  how many hits has; least reused url.
  """

  @doc """
  sort by total number of hits and return the least reused url

   ## Examples

      iex> least_reused_url(%{"url1" => 10, "url2" => 5})
      {:ok, "url2"}

      iex> least_reused_url(%{})
      {:error, :not_found}
  """
  @spec least_reused_url(map) :: {:ok, String.t()} | {:error, :not_found}
  def least_reused_url(urls) do
    {url, _hits} =
      urls
      |> Enum.sort(fn {_, hits1}, {_, hits2} -> hits1 <= hits2 end)
      |> List.first()

    {:ok, url}
  end
end
