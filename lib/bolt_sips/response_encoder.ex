defmodule Bolt.Sips.ResponseEncoder do
  @moduledoc """
  This module provides functions to encode a query result or data containing Bolt.Sips.Types
  into various format.

  For now, only JSON is supported.

  Encoding is  handled by protocols to allow override if a  specific implemention is required.
  See targeted protocol documentation for more information

  """

  @doc """
  Encode the data in json format.

  This is done is 2 steps:
  - first, the data is converted into a jsonable format
  - the result is encoded in json via Jason

  Both of these steps are overridable, see:
  - for step 1: `Bolt.Sips.ResponseEncoder.Json`
  - for step 2 (depending of your preferred library):
  - `Bolt.Sips.ResponseEncoder.Json.Jason`
  - `Bolt.Sips.ResponseEncoder.Json.Poison`

  ## Example

      iex> data = %{"t1" => %Bolt.Sips.Types.Node{
      ...>     id: 69,
      ...>     labels: ["Test"],
      ...>     properties: %{
      ...>       "created" => %Bolt.Sips.Types.DateTimeWithTZOffset{
      ...>         naive_datetime: ~N[2016-05-24 13:26:08.543],
      ...>         timezone_offset: 7200
      ...>       },
      ...>       "uuid" => 12345
      ...>     }
      ...>   }
      ...> }
      iex> Bolt.Sips.ResponseEncoder.encode(data, :json)
      {:ok, ~S|{"t1":{"id":69,"labels":["Test"],"properties":{"created":"2016-05-24T13:26:08.543+02:00","uuid":12345}}}|}

      iex> Bolt.Sips.ResponseEncoder.encode("\\xFF", :json)
      {:error, %Jason.EncodeError{message: "invalid byte 0xFF in <<255>>"}}
  """
  @spec encode(any(), :json) ::
          {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()}
  def encode(response, :json) do
    response
    |> jsonable_response()
    |> Jason.encode()
  end

  @doc """
  Encode the data in json format.

  Similar to `encode/1` except it will unwrap the error tuple and raise in case of errors.

  ## Example

      iex> data = %{"t1" => %Bolt.Sips.Types.Node{
      ...>     id: 69,
      ...>     labels: ["Test"],
      ...>     properties: %{
      ...>       "created" => %Bolt.Sips.Types.DateTimeWithTZOffset{
      ...>         naive_datetime: ~N[2016-05-24 13:26:08.543],
      ...>         timezone_offset: 7200
      ...>       },
      ...>       "uuid" => 12345
      ...>     }
      ...>   }
      ...> }
      iex> Bolt.Sips.ResponseEncoder.encode!(data, :json)
      ~S|{"t1":{"id":69,"labels":["Test"],"properties":{"created":"2016-05-24T13:26:08.543+02:00","uuid":12345}}}|

      iex> Bolt.Sips.ResponseEncoder.encode!("\\xFF", :json)
      ** (Jason.EncodeError) invalid byte 0xFF in <<255>>
  """
  @spec encode!(any(), :json) :: String.t() | no_return()
  def encode!(response, :json) do
    response
    |> jsonable_response()
    |> Jason.encode!()
  end

  defp jsonable_response(response) do
    response
    |> Bolt.Sips.ResponseEncoder.Json.encode()
  end
end
