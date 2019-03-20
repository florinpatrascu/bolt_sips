defmodule Bolt.Sips.Internals.PackStream.Markers do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
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

      # Node
      @node_marker 0x4E

      # Relationship
      @relationship_marker 0x52

      # Unbounded relationship
      @unbounded_relationship_marker 0x72

      # Path
      @path_marker 0x50

      # Local Time
      @local_time_signature 0x74
      @local_time_struct_size 1

      # Time With TZ Offset
      @time_with_tz_signature 0x54
      @time_with_tz_struct_size 2

      # Date
      @date_signature 0x44
      @date_struct_size 1

      # Local DateTime
      @local_datetime_signature 0x64
      @local_datetime_struct_size 2

      # Datetime with TZ offset
      @datetime_with_zone_offset_signature 0x46
      @datetime_with_zone_offset_struct_size 3

      # Datetime with TZ id
      @datetime_with_zone_id_signature 0x66
      @datetime_with_zone_id_struct_size 3

      # Duration
      @duration_signature 0x45
      @duration_struct_size 4

      # Point 2D
      @point2d_signature 0x58
      @point2d_struct_size 3

      # Point 3D
      @point3d_signature 0x59
      @point3d_struct_size 4
    end
  end
end

defmodule Bolt.Sips.Internals.PackStream.MarkersHelper do
  @moduledoc false
  use Bolt.Sips.Internals.PackStream.Markers

  @doc """
  Return the list of valid signatures (for data encoding).
  """
  @spec valid_signatures() :: [integer()]
  def valid_signatures() do
    [
      @local_time_signature,
      @time_with_tz_signature,
      @date_signature,
      @local_datetime_signature,
      @datetime_with_zone_offset_signature,
      @datetime_with_zone_id_signature,
      @duration_signature,
      @point2d_signature,
      @point3d_signature
    ]
  end
end
