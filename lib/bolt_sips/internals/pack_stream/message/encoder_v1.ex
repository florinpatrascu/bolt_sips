defmodule Bolt.Sips.Internals.PackStream.Message.EncoderV1 do
  @moduledoc false
  use Bolt.Sips.Internals.PackStream.Message.Signatures
  alias Bolt.Sips.Internals.PackStream.Message.Encoder

  @valid_signatures [
    @ack_failure_signature,
    @discard_all_signature,
    @init_signature,
    @pull_all_signature,
    @reset_signature,
    @run_signature
  ]

  @valid_message_types [
    :ack_failure,
    :discard_all,
    :init,
    :pull_all,
    :reset,
    :run
  ]

  @doc """
  Return the valid signatures for bolt V1
  """
  @spec valid_signatures() :: [integer()]
  def valid_signatures() do
    @valid_signatures
  end

  @spec signature(Bolt.Sips.Internals.PackStream.Message.out_signature()) :: integer()
  defp signature(:ack_failure), do: @ack_failure_signature
  defp signature(:discard_all), do: @discard_all_signature
  defp signature(:init), do: @init_signature
  defp signature(:pull_all), do: @pull_all_signature
  defp signature(:reset), do: @reset_signature
  defp signature(:run), do: @run_signature

  @doc """
  Encode INIT message without auth token
  """
  @spec encode({Bolt.Sips.Internals.PackStream.Message.out_signature(), list()}, integer()) ::
          Bolt.Sips.Internals.PackStream.Message.encoded()
  def encode({:init, []}, bolt_version) do
    encode({:init, [{}]}, bolt_version)
  end

  @doc """
  Encode INIT message with a valid auth token.
  The auth token is tuple formated as: {user, password}
  """
  def encode({:init, [auth]}, bolt_version) do
    do_encode(:init, [Encoder.client_name(), auth_params(auth)], bolt_version)
  end

  @doc """
  Encode RUN message with its data: statement and parameters
  """
  def encode({:run, [statement]}, bolt_version) do
    do_encode(:run, [statement, %{}], bolt_version)
  end

  @doc """
  Encode messages that don't need any data formating
  """
  def encode({message_type, data}, bolt_version) when message_type in @valid_message_types do
    do_encode(message_type, data, bolt_version)
  end

  @doc """
  Encode  messages

  # Supported messages

  ## INIT
  Usage: intialize the session.

  Signature: `0x01`

  Struct: `client_name` `auth_token`

  with:

  | data | type |
  |-----|-----|
  |client_name | string|
  |auth_token | map: {scheme: string, principal: string, credentials: string}|

  Examples (excluded from doctest because client_name changes at each bolt_sips version)

      # without auth token
      diex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      EncoderV1.encode({:init, []}, 1)
      <<0x0, 0x10, 0xB2, 0x1, 0x8C, 0x42, 0x6F, 0x6C, 0x74, 0x65, 0x78, 0x2F, 0x30, 0x2E, 0x34,
      0x2E, 0x30, 0xA0, 0x0, 0x0>>

      # with auth token
      # The auth token is tuple formated as: {user, password}
      diex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      diex> EncoderV1.encode({:init, [{"neo4j", "password"}]})
      <<0x0, 0x42, 0xB2, 0x1, 0x8C, 0x42, 0x6F, 0x6C, 0x74, 0x65, 0x78, 0x2F, 0x30, 0x2E, 0x34,
      0x2E, 0x30, 0xA3, 0x8B, 0x63, 0x72, 0x65, 0x64, 0x65, 0x6E, 0x74, 0x69, 0x61, 0x6C, 0x73,
      0x88, 0x70, 0x61, 0x73, 0x73, 0x77, 0x6F, 0x72, 0x64, 0x89, 0x70, 0x72, 0x69, 0x6E, 0x63,
      0x69, 0x70, 0x61, 0x6C, 0x85, ...>>


  ## RUN
  Usage: pass statement for execution to the server.

  Signature: `0x10`

  Struct: `statement` `parameters`

  with:

  | data | type |
  |-----|-----|
  | statement | string |
  | parameters | map |

  Examples
      # without parameters
      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      iex> EncoderV1.encode({:run, ["RETURN 1 AS num"]}, 1)
      <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x31, 0x20, 0x41,
      0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0, 0x0>>
      # with parameters
      iex> EncoderV1.encode({:run, ["RETURN {num} AS num", %{num: 1}]}, 1)
      <<0x0, 0x1D, 0xB2, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x7B, 0x6E,
      0x75, 0x6D, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA1, 0x83, 0x6E, 0x75, 0x6D,
      0x1, 0x0, 0x0>>

  ## ACK_FAILURE
  Usage: Acknowledge a failure the server has sent.

  Signature: `0x0E`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      iex> EncoderV1.encode({:ack_failure, []}, 1)
      <<0x0, 0x2, 0xB0, 0xE, 0x0, 0x0>>

  ## DISCARD_ALL
  Uage: Discard all remaining items from the active result stream.

  Signature: `0x2F`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      iex> EncoderV1.encode({:discard_all, []}, 1)
      <<0x0, 0x2, 0xB0, 0x2F, 0x0, 0x0>>

  ## PULL_ALL
  Usage: Retrieve all remaining items from the active result stream.

  Signature: `0x3F`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      iex> EncoderV1.encode({:pull_all, []}, 1)
      <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>>

  ## RESET
  Usage: Return the current session to a "clean" state.

  Signature: `0x0F`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV1
      iex> EncoderV1.encode({:reset, []}, 1)
      <<0x0, 0x2, 0xB0, 0xF, 0x0, 0x0>>
  """
  def encode(_data, _bolt_version) do
    {:error, :not_implemented}
  end

  defp do_encode(message_type, data, bolt_version) do
    signature = signature(message_type)
    Encoder.encode_message(message_type, signature, data, bolt_version)
  end

  # Format the auth params
  @spec auth_params({} | {String.t(), String.t()}) :: map()
  defp auth_params({}), do: %{}

  defp auth_params({username, password}) do
    %{
      scheme: "basic",
      principal: username,
      credentials: password
    }
  end
end
