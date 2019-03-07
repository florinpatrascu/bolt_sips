defmodule Bolt.Sips.Internals.PackStream.EncoderHelper do
  alias Bolt.Sips.Internals.PackStream.EncodeError

  @available_bolt_versions [1, 2]

  @doc """
  List bolt versions.
  Only bolt version that have specific encoding functions are listed.

  """
  def available_bolt_versions(), do: @available_bolt_versions

  @doc """
  For the given `data_type` and `bolt_version`, determine the right enconding function
  and call it agains `data`
  """
  @spec call_encode(atom(), any(), any()) :: binary() | EncodeError.t()
  def call_encode(data_type, data, bolt_version)
      when is_integer(bolt_version) and not (bolt_version in @available_bolt_versions) do
    if bolt_version > List.last(@available_bolt_versions) do
      call_encode(data_type, data, List.last(@available_bolt_versions))
    else
      raise EncodeError,
        data_type: data_type,
        data: data,
        bolt_version: bolt_version,
        message: "Unsupported encoder version"
    end
  end

  def call_encode(data_type, data, bolt_version)
      when is_integer(bolt_version) and bolt_version in @available_bolt_versions do
    do_call_encode(data_type, data, bolt_version, bolt_version)
  end

  def call_encode(data_type, data, bolt_version) do
    raise EncodeError,
      data_type: data_type,
      data: data,
      bolt_version: bolt_version,
      message: "Unsupported encoder version"
  end

  # Check if the encoder for the given bolt version is capable of encoding the given data
  # If it is the case, the encoding function will be called
  # If not, fallback to previous bolt version
  #
  # If encoding function is present in none of the bolt  version, an error will be raised
  @spec do_call_encode(atom(), any(), integer(), nil | integer()) :: binary() | EncodeError.t()
  defp do_call_encode(data_type, data, original_version, nil) do
    raise EncodeError,
      data_type: data_type,
      data: data,
      bolt_version: original_version,
      message: "Encoding function not implemented for"
  end

  defp do_call_encode(data_type, data, original_version, used_version) do
    module = Module.concat(["Bolt.Sips.Internals.PackStream", "EncoderV#{used_version}"])
    func_atom = String.to_atom("encode_#{data_type}")

    with true <- Code.ensure_loaded?(module),
         true <- Kernel.function_exported?(module, func_atom, 2) do
      Kernel.apply(module, func_atom, [data, original_version])
    else
      _ ->
        do_call_encode(
          data_type,
          data,
          original_version,
          previous_version(used_version, @available_bolt_versions)
        )
    end
  end

  # Retrieve previous version
  @spec previous_version(integer(), list()) :: nil | integer()
  defp previous_version(version, available_versions) do
    available_versions
    |> Enum.take_while(&(&1 < version))
    |> List.last()
  end
end
