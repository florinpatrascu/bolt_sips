defmodule Bolt.Sips.Internals.PackStream.V1 do
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      
      @last_version Bolt.Sips.Internals.BoltVersionHelper.last()

      @int8 -127..-17
      @int16_low -32_768..-129
      @int16_high 128..32_767
      @int32_low -2_147_483_648..-32_769
      @int32_high 32_768..2_147_483_647
      @int64_low -9_223_372_036_854_775_808..-2_147_483_649
      @int64_high 2_147_483_648..9_223_372_036_854_775_807
      # Null
      @null_marker 0xC0

      # Boolean
      @true_marker 0xC3
      @false_marker 0xC2

      # String
      @tiny_bitstring_marker 0x8
      @bitstring8_marker 0xD0
      @bitstring16_marker 0xD1
      @bitstring32_marker 0xD2

      # Integer
      @int8_marker 0xC8
      @int16_marker 0xC9
      @int32_marker 0xCA
      @int64_marker 0xCB

      # Float
      @float_marker 0xC1

      # List
      @tiny_list_marker 0x9
      @list8_marker 0xD4
      @list16_marker 0xD5
      @list32_marker 0xD6

      # Map
      @tiny_map_marker 0xA
      @map8_marker 0xD8
      @map16_marker 0xD9
      @map32_marker 0xDA

      # Structure
      @tiny_struct_marker 0xB
      @struct8_marker 0xDC
      @struct16_marker 0xDD

      @spec do_call_encode(atom(), any(), integer()) ::
              binary() | PackStreamError.t()

      # Atoms
      defp do_call_encode(:atom, nil, bolt_version) when bolt_version <= @last_version do
        <<@null_marker>>
      end

      defp do_call_encode(:atom, true, bolt_version) when bolt_version <= @last_version do
        <<@true_marker>>
      end

      defp do_call_encode(:atom, false, bolt_version) when bolt_version <= @last_version do
        <<@false_marker>>
      end

      defp do_call_encode(:atom, other, bolt_version) when bolt_version <= @last_version do
        call_encode(:string, other |> Atom.to_string(), bolt_version)
      end

      # Strings 
      defp do_call_encode(:string, string, bolt_version)
           when bolt_version <= @last_version and byte_size(string) <= 15 do
        [<<@tiny_bitstring_marker::4, byte_size(string)::4>>, string]
      end

      defp do_call_encode(:string, string, bolt_version)
           when bolt_version <= @last_version and byte_size(string) <= 255 do
        [<<@bitstring8_marker, byte_size(string)::8>>, string]
      end

      defp do_call_encode(:string, string, bolt_version)
           when bolt_version <= @last_version and byte_size(string) <= 65_535 do
        [<<@bitstring16_marker, byte_size(string)::16>>, string]
      end

      defp do_call_encode(:string, string, bolt_version)
           when bolt_version <= @last_version and byte_size(string) <= 4_294_967_295 do
        [<<@bitstring32_marker, byte_size(string)::32>>, string]
      end

      # Integer
      defp do_call_encode(:integer, integer, bolt_version)
           when bolt_version <= @last_version and integer in -16..127 do
        <<integer>>
      end

      defp do_call_encode(:integer, integer, bolt_version)
           when bolt_version <= @last_version and integer in @int8 do
        <<@int8_marker, integer>>
      end

      defp do_call_encode(:integer, integer, bolt_version)
           when bolt_version <= @last_version and integer in @int16_low
           when bolt_version <= @last_version and integer in @int16_high do
        <<@int16_marker, integer::16>>
      end

      defp do_call_encode(:integer, integer, bolt_version)
           when bolt_version <= @last_version and integer in @int32_low
           when bolt_version <= @last_version and integer in @int32_high do
        <<@int32_marker, integer::32>>
      end

      defp do_call_encode(:integer, integer, bolt_version)
           when bolt_version <= @last_version and integer in @int64_low
           when bolt_version <= @last_version and integer in @int64_high do
        <<@int64_marker, integer::64>>
      end

      # Float

      defp do_call_encode(:float, number, bolt_version) when bolt_version <= 3 do
        <<@float_marker, number::float>>
      end

      # lists
      defp do_call_encode(:list, list, bolt_version)
           when bolt_version <= @last_version and length(list) <= 15 do
        [<<@tiny_list_marker::4, length(list)::4>>, encode_list_data(list, bolt_version)]
      end

      defp do_call_encode(:list, list, bolt_version)
           when bolt_version <= @last_version and length(list) <= 255 do
        [<<@list8_marker, length(list)::8>>, encode_list_data(list, bolt_version)]
      end

      defp do_call_encode(:list, list, bolt_version)
           when bolt_version <= @last_version and length(list) <= 65_535 do
        [<<@list16_marker, length(list)::16>>, encode_list_data(list, bolt_version)]
      end

      defp do_call_encode(:list, list, bolt_version)
           when bolt_version <= @last_version and length(list) <= 4_294_967_295 do
        [<<@list32_marker, length(list)::32>>, encode_list_data(list, bolt_version)]
      end

      # maps
      defp do_call_encode(:map, map, bolt_version)
           when bolt_version <= @last_version and map_size(map) <= 15 do
        [<<@tiny_map_marker::4, map_size(map)::4>>, encode_kv(map, bolt_version)]
      end

      defp do_call_encode(:map, map, bolt_version)
           when bolt_version <= @last_version and map_size(map) <= 255 do
        [<<@map8_marker, map_size(map)::8>>, encode_kv(map, bolt_version)]
      end

      defp do_call_encode(:map, map, bolt_version)
           when bolt_version <= @last_version and map_size(map) <= 65_535 do
        [<<@map16_marker, map_size(map)::16>>, encode_kv(map, bolt_version)]
      end

      defp do_call_encode(:map, map, bolt_version)
           when bolt_version <= @last_version and map_size(map) <= 4_294_967_295 do
        [<<@map32_marker, map_size(map)::32>>, encode_kv(map, bolt_version)]
      end

      # Structs
      defp do_call_encode(:struct, {signature, list}, bolt_version)
           when bolt_version <= @last_version and length(list) <= 15 do
        [
          <<@tiny_struct_marker::4, length(list)::4, signature>>,
          encode_list_data(list, bolt_version)
        ]
      end

      defp do_call_encode(:struct, {signature, list}, bolt_version)
           when bolt_version <= @last_version and length(list) <= 255 do
        [<<@struct8_marker::8, length(list)::8, signature>>, encode_list_data(list, bolt_version)]
      end

      defp do_call_encode(:struct, {signature, list}, bolt_version)
           when bolt_version <= @last_version and length(list) <= 65_535 do
        [
          <<@struct16_marker::8, length(list)::16, signature>>,
          encode_list_data(list, bolt_version)
        ]
      end
    end
  end
end
