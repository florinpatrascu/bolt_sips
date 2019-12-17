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
  def encode(data, bolt_version) do
    Encoder.encode(data, bolt_version)
  end

end
