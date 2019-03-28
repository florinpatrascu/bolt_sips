defmodule Bolt.Sips.Internals.PackStream.Message.EncoderV3 do
  @moduledoc false
  use Bolt.Sips.Internals.PackStream.Message.Signatures
  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Metadata

  @valid_signatures [
    @begin_signature,
    @commit_signature,
    @discard_all_signature,
    @goodbye_signature,
    @hello_signature,
    @pull_all_signature,
    @reset_signature,
    @rollback_signature,
    @run_signature
  ]

  @valid_message_types [
    :begin,
    :commit,
    :goodbye,
    :hello,
    :rollback,
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
  # defp signature(:ack_failure), do: @ack_failure_signature
  # defp signature(:discard_all), do: @discard_all_signature
  # defp signature(:pull_all), do: @pull_all_signature
  # defp signature(:reset), do: @reset_signature
  defp signature(:begin), do: @begin_signature
  defp signature(:commit), do: @commit_signature
  defp signature(:goodbye), do: @goodbye_signature
  defp signature(:hello), do: @hello_signature
  defp signature(:rollback), do: @rollback_signature
  defp signature(:run), do: @run_signature

  @doc """
  Encode HELLO message without auth token
  """
  @spec encode({Bolt.Sips.Internals.PackStream.Message.out_signature(), list()}, integer()) ::
          Bolt.Sips.Internals.PackStream.Message.encoded()
          | {:error, :not_implemented}
          | {:error, :invalid_message}
  def encode({:hello, []}, bolt_version) do
    encode({:hello, [{}]}, bolt_version)
  end

  @doc """
  Encode INIT message with a valid auth token.
  The auth token is tuple formated as: {user, password}
  """
  def encode({:hello, [auth]}, bolt_version) do
    do_encode(:hello, [auth_params(auth)], bolt_version)
  end

  @doc """
  Encode BEGIN message without metadata.

  BEGIN is used to open a transaction.
  """
  def encode({:begin, []}, bolt_version) do
    encode({:begin, [%{}]}, bolt_version)
  end

  @doc """
  Encode BEGIN message with metadata
  """
  def encode({:begin, [%Metadata{} = metadata]}, bolt_version) do
    do_encode(:begin, [Metadata.to_map(metadata)], bolt_version)
  end

  def encode({:begin, [%{} = map]}, bolt_version) when map_size(map) == 0 do
    {:ok, metadata} = Metadata.new(%{})
    encode({:begin, [metadata]}, bolt_version)
  end

  def encode({:begin, _}, _) do
    {:error, :invalid_data}
  end

  @doc """
  Encode RUN without params nor metadata
  """
  def encode({:run, [statement]}, bolt_version) do
    do_encode(:run, [statement, %{}, %{}], bolt_version)
  end

  @doc """
  Encode RUN with params but without metadata
  """
  def encode({:run, [statement, params]}, bolt_version) do
    do_encode(:run, [statement, params, %{}], bolt_version)
  end

  @doc """
  Encode RUN with params and metadata
  """
  def encode({:run, [statement, params, %Metadata{} = metadata]}, bolt_version) do
    do_encode(:run, [statement, params, Metadata.to_map(metadata)], bolt_version)
  end

  @doc """
  INIT is no more a valid message in Bolt V3
  """
  def encode({:init, _}, _) do
    {:error, :invalid_message}
  end

  @doc """
  Encode messages that don't need any data formating
  """
  def encode({message_type, data}, bolt_version) when message_type in @valid_message_types do
    do_encode(message_type, data, bolt_version)
  end

  @doc """
  Encode Bolt V3 messages

  Not that INIT is not valid in bolt V3, it is replaced by HELLO

  ## HELLO
  Usage: intialize the session.

  Signature: `0x01` (Same as INIT in previous bolt version)

  Struct: `auth_parms`

  with:

  | data | type |
  |-----|-----|
  |auth_token | map: {scheme: string, principal: string, credentials: string, user_agent: string}|

  Note: `user_agent` is equivalent to `client_name` in bolt previous version.

  Examples (excluded from doctest because client_name changes at each bolt_sips version)

      # without auth token
      diex> EncoderV3.encode({:hello, []}, 3)
      <<0x0, 0x1D, 0xB1, 0x1, 0xA1, 0x8A, 0x75, 0x73, 0x65, 0x72, 0x5F, 0x61, 0x67, 0x65, 0x6E,
      0x74, 0x8E, 0x42, 0x6F, 0x6C, 0x74, 0x53, 0x69, 0x70, 0x73, 0x2F, 0x31, 0x2E, 0x34, 0x2E,
      0x30, 0x0, 0x0>>

      # with auth token
      diex(20)> EncoderV3.encode({:hello, [{"neo4j", "test"}]}, 3)
      <<0x0, 0x4B, 0xB1, 0x1, 0xA4, 0x8B, 0x63, 0x72, 0x65, 0x64, 0x65, 0x6E, 0x74, 0x69, 0x61,
      0x6C, 0x73, 0x84, 0x74, 0x65, 0x73, 0x74, 0x89, 0x70, 0x72, 0x69, 0x6E, 0x63, 0x69, 0x70,
      0x61, 0x6C, 0x85, 0x6E, 0x65, 0x6F, 0x34, 0x6A, 0x86, 0x73, 0x63, 0x68, 0x65, 0x6D, 0x65,
      0x85, 0x62, 0x61, 0x73, 0x69, ...>>

  ## GOODBYE
  Usage: close the connection with the server

  Signature: `0x02`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> EncoderV3.encode({:goodbye, []}, 3)
      <<0x0, 0x2, 0xB0, 0x2, 0x0, 0x0>>

  ## BEGIN
  Usage: Open a transaction

  Signature: `0x11`

  Struct: `metadata`

  with:

  | data | type |
  |------|------|
  | metadata | See Bolt.Sips.Metadata

  Example

      # without metadata
      # iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      # iex> EncoderV3.encode({:begin, []}, 3)
      # <<0x0, 0x3, 0xB1, 0x11, 0xA0, 0x0, 0x0>>

      # # with metadata
      # iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      # iex> alias Bolt.Sips.Metadata
      # iex> {:ok, metadata} = Metadata.new(%{tx_timeout: 5000})
      # {:ok,
      # %Bolt.Sips.Metadata{
      #   bookmarks: nil,
      #   metadata: nil,
      #   tx_timeout: 5000
      # }}
      # iex> EncoderV3.encode({:begin, [metadata]}, 3)
      # <<0x0, 0x11, 0xB1, 0x11, 0xA1, 0x8A, 0x74, 0x78, 0x5F, 0x74, 0x69, 0x6D, 0x65, 0x6F, 0x75,
      # 0x74, 0xC9, 0x13, 0x88, 0x0, 0x0>>

  ## COMMIT
  Usage: commit the currently open transaction

  Signature: `0x12`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> EncoderV3.encode({:commit, []}, 3)
      <<0x0, 0x2, 0xB0, 0x12, 0x0, 0x0>>

  ## ROLLBACK
  Usage: rollback the currently open transaction

  Signature: `0x13`

  Struct: no data

  Example

      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> EncoderV3.encode({:rollback, []}, 3)
      <<0x0, 0x2, 0xB0, 0x13, 0x0, 0x0>>

  ## RUN
  Usage: pass statement for execution to the server. Same as in bolt previous version.
  The only difference: `metadata` are passed as well since bolt v3.

  Signature: `0x10`

  Struct: `statement` `parameters` `metadata`

  with:

  | data | type |
  |-----|-----|
  | statement | string |
  | parameters | map |
  | metadata | See Bolt.Sips.Metadata

  Example

      # without params nor metadata
      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> EncoderV3.encode({:run, ["RETURN 'hello' AS str"]}, 3)
      <<0x0, 0x1B, 0xB3, 0x10, 0xD0, 0x15, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x27, 0x68,
      0x65, 0x6C, 0x6C, 0x6F, 0x27, 0x20, 0x41, 0x53, 0x20, 0x73, 0x74, 0x72, 0xA0, 0xA0, 0x0,
      0x0>>

      # without params but with metadata
      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> alias Bolt.Sips.Metadata
      iex> {:ok, metadata} = Metadata.new(%{tx_timeout: 4500})
      {:ok,
      %Bolt.Sips.Metadata{
        bookmarks: nil,
        metadata: nil,
        tx_timeout: 4500
      }}
      iex> EncoderV3.encode({:run, ["RETURN 'hello' AS str", %{}, metadata]}, 3)
      <<0x0, 0x29, 0xB3, 0x10, 0xD0, 0x15, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x27, 0x68,
      0x65, 0x6C, 0x6C, 0x6F, 0x27, 0x20, 0x41, 0x53, 0x20, 0x73, 0x74, 0x72, 0xA0, 0xA1, 0x8A,
      0x74, 0x78, 0x5F, 0x74, 0x69, 0x6D, 0x65, 0x6F, 0x75, 0x74, 0xC9, 0x11, 0x94, 0x0, 0x0>>

      # with params but without metadata
      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> EncoderV3.encode({:run, ["RETURN {str} AS str", %{str: "hello"}]}, 3)
      <<0x0, 0x23, 0xB3, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x7B, 0x73,
      0x74, 0x72, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x73, 0x74, 0x72, 0xA1, 0x83, 0x73, 0x74, 0x72,
      0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xA0, 0x0, 0x0>>

      # with params and metadata
      iex> alias Bolt.Sips.Internals.PackStream.Message.EncoderV3
      iex> alias Bolt.Sips.Metadata
      iex> {:ok, metadata} = Metadata.new(%{tx_timeout: 4500})
      {:ok,
      %Bolt.Sips.Metadata{
        bookmarks: nil,
        metadata: nil,
        tx_timeout: 4500
      }}
      iex> EncoderV3.encode({:run, ["RETURN {str} AS str", %{str: "hello"}, metadata]}, 3)
      <<0x0, 0x31, 0xB3, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x7B, 0x73,
      0x74, 0x72, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x73, 0x74, 0x72, 0xA1, 0x83, 0x73, 0x74, 0x72,
      0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xA1, 0x8A, 0x74, 0x78, 0x5F, 0x74, 0x69, 0x6D, 0x65,
      0x6F, 0x75, 0x74, 0xC9, 0x11, 0x94, 0x0, 0x0>>
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
  defp auth_params({}), do: user_agent()

  defp auth_params({username, password}) do
    %{
      scheme: "basic",
      principal: username,
      credentials: password
    }
    |> Map.merge(user_agent())
  end

  defp user_agent() do
    %{user_agent: Encoder.client_name()}
  end
end
