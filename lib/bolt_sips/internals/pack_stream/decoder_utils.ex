defmodule Bolt.Sips.Internals.PackStream.DecoderUtils do
  alias Bolt.Sips.Internals.PackStreamError

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      @last_version Bolt.Sips.Internals.BoltVersionHelper.last()

      def decode(data, bolt_version) when is_integer(bolt_version) do
        if bolt_version > @last_version do
          decode(data, @last_version)
        else
          raise PackStreamError,
            data: data,
            bolt_version: bolt_version,
            message: "Unsupported decoder version"
        end
      end

      def decode(_, _) do
        {:error, :not_implemented}
      end

      @doc """
      Decodes a struct
      """
      @spec decode_struct(binary(), integer(), integer()) :: {list(), list()}
      def decode_struct(struct, struct_size, bolt_version) do
        struct
        |> decode(bolt_version)
        |> Enum.split(struct_size)
      end

      @spec to_map(list()) :: map()
      defp to_map(map) do
        map
        |> Enum.chunk_every(2)
        |> Enum.map(&List.to_tuple/1)
        |> Map.new()
      end

      @spec decode_string(binary(), integer(), integer()) :: list()
      defp decode_string(bytes, str_length, bolt_version) do
        <<string::binary-size(str_length), rest::binary>> = bytes

        [string | decode(rest, bolt_version)]
      end

      @spec decode_list(binary(), integer(), integer()) :: list()
      defp decode_list(list, list_size, bolt_version) do
        {list, rest} = list |> decode(bolt_version) |> Enum.split(list_size)
        [list | rest]
      end

      @spec decode_map(binary(), integer(), integer()) :: list()
      defp decode_map(map, entries, bolt_version) do
        {map, rest} = map |> decode(bolt_version) |> Enum.split(entries * 2)

        [to_map(map) | rest]
      end
    end
  end
end
