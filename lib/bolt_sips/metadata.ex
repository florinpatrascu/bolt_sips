defmodule Bolt.Sips.Metadata do
  @moduledoc false
  defstruct [:bookmarks, :tx_timeout, :metadata]

  @type t :: %__MODULE__{
          bookmarks: [String.t()],
          tx_timeout: non_neg_integer(),
          metadata: map()
        }

  alias Bolt.Sips.Metadata

  @doc """
  Create a new metadata structure.
  Data must be valid.
  """
  @spec new(map()) :: {:ok, Bolt.Sips.Metadata.t()} | {:error, String.t()}
  def new(data) do
    with {:ok, data} <- check_keys(data),
         {:ok, bookmarks} <- validate_bookmarks(Map.get(data, :bookmarks, [])),
         {:ok, tx_timeout} <- validate_timeout(Map.get(data, :tx_timeout)),
         {:ok, metadata} <- validate_metadata(Map.get(data, :metadata, %{})) do
      {:ok,
       %__MODULE__{
         bookmarks: bookmarks,
         tx_timeout: tx_timeout,
         metadata: metadata
       }}
    else
      error -> error
    end
  end

  @doc """
  Convert the Metadata struct to a map.
  All `nil` will be stripped
  """
  @spec to_map(Bolt.Sips.Metadata.t()) :: map()
  def to_map(metadata) do
    with {:ok, metadata} <- check_keys(Map.from_struct(metadata)) do
      metadata
      |> Map.from_struct()
      |> Enum.filter(fn {_, value} -> value != nil end)
      |> Enum.into(%{})
    else
      error -> error
    end
  end

  defp check_keys(data) do
    try do
      {:ok, struct!(Metadata, data)}
    rescue
      _ in KeyError -> {:error, "[Metadata] Invalid keys"}
    end
  end

  @spec validate_bookmarks(any()) :: {:ok, list()} | {:ok, nil} | {:error, String.t()}
  defp validate_bookmarks(bookmarks)
       when (is_list(bookmarks) and length(bookmarks) > 0) or is_nil(bookmarks) do
    {:ok, bookmarks}
  end

  defp validate_bookmarks([]) do
    {:ok, nil}
  end

  defp validate_bookmarks(_) do
    {:error, "[Metadata] Invalid bookmkarks. Should be a list."}
  end

  @spec validate_timeout(any()) :: {:ok, integer()} | {:error, String.t()}
  defp validate_timeout(timeout) when (is_integer(timeout) and timeout > 0) or is_nil(timeout) do
    {:ok, timeout}
  end

  defp validate_timeout(nil) do
    {:ok, nil}
  end

  defp validate_timeout(_) do
    {:error, "[Metadata] Invalid timeout. Should be a positive integer."}
  end

  @spec validate_metadata(any()) :: {:ok, map()} | {:ok, nil} | {:error, String.t()}
  defp validate_metadata(metadata)
       when (is_map(metadata) and map_size(metadata) > 0) or is_nil(metadata) do
    {:ok, metadata}
  end

  defp validate_metadata(%{}) do
    {:ok, nil}
  end

  defp validate_metadata(_) do
    {:error, "[Metadata] Invalid timeout. Should be a valid map or nil."}
  end
end
