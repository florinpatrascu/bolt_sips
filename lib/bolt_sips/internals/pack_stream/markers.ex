defmodule Bolt.Sips.Internals.PackStream.Markers do
  defmacro __using__(_opts) do
    quote do
      @null_marker 0xC0
      @true_marker 0xC3
      @false_marker 0xC2

      @tiny_bitstring_marker 0x8
      @bitstring8_marker 0xD0
      @bitstring16_marker 0xD1
      @bitstring32_marker 0xD2

      @int8_marker 0xC8
      @int16_marker 0xC9
      @int32_marker 0xCA
      @int64_marker 0xCB

      @float_marker 0xC1

      @tiny_list_marker 0x9
      @list8_marker 0xD4
      @list16_marker 0xD5
      @list32_marker 0xD6

      @tiny_map_marker 0xA
      @map8_marker 0xD8
      @map16_marker 0xD9
      @map32_marker 0xDA

      @tiny_struct_marker 0xB
      @struct8_marker 0xDC
      @struct16_marker 0xDD
    end
  end
end
