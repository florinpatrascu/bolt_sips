defmodule Bolt.Sips.Internals.PackStream.EncoderHelper do
  @moduledoc false
  alias Bolt.Sips.Internals.PackStreamError
  alias Bolt.Sips.Internals.BoltVersionHelper
  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Types.{TimeWithTZOffset, DateTimeWithTZOffset, Duration, Point}

  @available_bolt_versions BoltVersionHelper.available_versions()

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

  @doc """
  For the given `data_type` and `bolt_version`, determine the right enconding function
  and call it agains `data`
  """
  @spec call_encode(atom(), any(), any()) :: binary() | PackStreamError.t()
  def call_encode(data_type, data, bolt_version)
      when is_integer(bolt_version) and bolt_version in @available_bolt_versions do
    do_call_encode(data_type, data, bolt_version)
  end

  def call_encode(data_type, data, bolt_version) when is_integer(bolt_version) do
    if bolt_version > BoltVersionHelper.last() do
      call_encode(data_type, data, BoltVersionHelper.last())
    else
      raise PackStreamError,
        data_type: data_type,
        data: data,
        bolt_version: bolt_version,
        message: "Unsupported encoder version"
    end
  end

  def call_encode(data_type, data, bolt_version) do
    raise PackStreamError,
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
  @spec do_call_encode(atom(), any(), integer()) ::
          binary() | PackStreamError.t()

  # Atoms
  defp do_call_encode(:atom, nil, bolt_version) when bolt_version <= 3 do 
    <<@null_marker>>
  end

  defp do_call_encode(:atom, true, bolt_version) when bolt_version <= 3 do 
    <<@true_marker>>
  end

  defp do_call_encode(:atom, false, bolt_version) when bolt_version <= 3 do 
    <<@false_marker>>
  end

  defp do_call_encode(:atom, other, bolt_version) when bolt_version <= 3 do
     call_encode(:string, other |> Atom.to_string(),bolt_version)
  end

  # Strings 
  defp do_call_encode(:string, string, bolt_version) when bolt_version <= 3 and byte_size(string) <= 15 do
    [<<@tiny_bitstring_marker::4, byte_size(string)::4>>, string]
  end

  defp do_call_encode(:string, string, bolt_version) when bolt_version <= 3 and byte_size(string) <= 255 do
    [<<@bitstring8_marker, byte_size(string)::8>>, string]
  end

  defp do_call_encode(:string, string, bolt_version) when bolt_version <= 3 and byte_size(string) <= 65_535 do
    [<<@bitstring16_marker, byte_size(string)::16>> , string]
  end

  defp do_call_encode(:string, string, bolt_version) when bolt_version <= 3 and byte_size(string) <= 4_294_967_295 do
    [<<@bitstring32_marker, byte_size(string)::32>>, string]
  end

  # Integer
  defp do_call_encode(:integer, integer, bolt_version) when bolt_version <= 3 and integer in -16..127 do
    <<integer>>
  end

  defp do_call_encode(:integer, integer, bolt_version) when bolt_version <= 3 and integer in @int8 do
    <<@int8_marker, integer>>
  end

  defp do_call_encode(:integer, integer, bolt_version) 
  when bolt_version <= 3 and integer in @int16_low 
  when bolt_version <= 3 and integer in @int16_high do
    <<@int16_marker, integer::16>>
  end

  defp do_call_encode(:integer, integer, bolt_version)
    when bolt_version <= 3 and integer in @int32_low 
    when bolt_version <= 3 and integer in @int32_high do
    <<@int32_marker, integer::32>>
  end

  defp do_call_encode(:integer,integer, bolt_version)
  when bolt_version <= 3 and integer in @int64_low 
  when bolt_version <= 3 and integer in @int64_high do
    <<@int64_marker, integer::64>>
  end

  #Float

  defp do_call_encode(:float, number, bolt_version) when bolt_version <= 3 do 
    <<@float_marker, number::float>>
  end

  # lists
  defp do_call_encode(:list, list, bolt_version) when bolt_version <= 3 and length(list) <= 15 do
    [<<@tiny_list_marker::4, length(list)::4>>,  encode_list_data(list, bolt_version)]
  end

  defp do_call_encode(:list, list, bolt_version) when bolt_version <= 3 and length(list) <= 255 do
    [<<@list8_marker, length(list)::8>>,  encode_list_data(list, bolt_version)]
  end

  defp do_call_encode(:list, list, bolt_version) when bolt_version <= 3 and length(list) <= 65_535 do
    [<<@list16_marker, length(list)::16>> , encode_list_data(list, bolt_version)]
  end

  defp do_call_encode(:list, list, bolt_version) when bolt_version <= 3 and length(list) <= 4_294_967_295 do
    [<<@list32_marker, length(list)::32>> , encode_list_data(list, bolt_version)]
  end

  # maps
  defp do_call_encode(:map, map, bolt_version) when bolt_version <= 3 and map_size(map) <= 15 do
    [<<@tiny_map_marker::4, map_size(map)::4>> , encode_kv(map, bolt_version)]
  end

  defp do_call_encode(:map, map, bolt_version) when bolt_version <= 3 and map_size(map) <= 255 do
    [<<@map8_marker, map_size(map)::8>> , encode_kv(map, bolt_version)]
  end

  defp do_call_encode(:map, map, bolt_version) when bolt_version <= 3 and map_size(map) <= 65_535 do
    [<<@map16_marker, map_size(map)::16>> , encode_kv(map, bolt_version)]
  end

  defp do_call_encode(:map, map, bolt_version) when bolt_version <= 3 and map_size(map) <= 4_294_967_295 do
    [<<@map32_marker, map_size(map)::32>> , encode_kv(map, bolt_version)]
  end

  # Structs
  defp do_call_encode(:struct, {signature, list}, bolt_version) when bolt_version <= 3 and length(list) <= 15 do
   [ <<@tiny_struct_marker::4, length(list)::4, signature>> , encode_list_data(list, bolt_version)]
  end

  defp do_call_encode(:struct, {signature, list}, bolt_version) when bolt_version <= 3 and length(list) <= 255 do
    [<<@struct8_marker::8, length(list)::8, signature>> , encode_list_data(list, bolt_version)]
  end

  defp do_call_encode(:struct, {signature, list}, bolt_version) when bolt_version <= 3 and length(list) <= 65_535 do
    [<<@struct16_marker::8, length(list)::16, signature>> , encode_list_data(list, bolt_version)]
  end

  defp do_call_encode(:local_time, local_time, bolt_version) when bolt_version >= 2 and bolt_version <= 3 do
    Encoder.encode({@local_time_signature, [day_time(local_time)]}, bolt_version)
  end

  defp do_call_encode(:time_with_tz, %TimeWithTZOffset{time: time, timezone_offset: offset}, bolt_version) 
  when bolt_version >= 2 and bolt_version <= 3 do
    Encoder.encode({@time_with_tz_signature, [day_time(time), offset]}, bolt_version)
  end

  defp do_call_encode(:date, date, bolt_version) 
  when bolt_version >= 2 and bolt_version <= 3 do
    epoch = Date.diff(date, ~D[1970-01-01])

    Encoder.encode({@date_signature, [epoch]}, bolt_version)
  end

  defp do_call_encode(:local_datetime, local_datetime, bolt_version) 
  when bolt_version >= 2 and bolt_version <= 3 do
    Encoder.encode({@local_datetime_signature, decompose_datetime(local_datetime)}, bolt_version)
  end

  defp do_call_encode(:datetime_with_tz_id, datetime, bolt_version) 
  when bolt_version >= 2 and bolt_version <= 3 do
    data = decompose_datetime(DateTime.to_naive(datetime)) ++ [datetime.time_zone]

    Encoder.encode({@datetime_with_zone_id_signature, data}, bolt_version)
  end

  defp do_call_encode(:datetime_with_tz_offset,
        %DateTimeWithTZOffset{naive_datetime: ndt, timezone_offset: tz_offset},
        bolt_version
      ) 
  when bolt_version >= 2 and bolt_version <= 3 do
    data = decompose_datetime(ndt) ++ [tz_offset]
    Encoder.encode({@datetime_with_zone_offset_signature, data}, bolt_version)
  end

  defp do_call_encode(:duration, %Duration{} = duration, bolt_version) 
  when bolt_version >= 2 and bolt_version <= 3 do
    Encoder.encode({@duration_signature, compact_duration(duration)}, bolt_version)
  end

  defp do_call_encode(:point, %Point{z: nil} = point, bolt_version)
  when bolt_version >= 2 and bolt_version <= 3 do
    Encoder.encode({@point2d_signature, [point.srid, point.x, point.y]}, bolt_version)
  end

  defp do_call_encode(:point, %Point{} = point, bolt_version)
  when bolt_version >= 2 and bolt_version <= 3 do
    Encoder.encode({@point3d_signature, [point.srid, point.x, point.y, point.z]}, bolt_version)
  end

  defp do_call_encode(data_type, data, original_version) do
    raise PackStreamError,
      data_type: data_type,
      data: data,
      bolt_version: original_version,
      message: "Encoding function not implemented for"
  end

  @spec encode_list_data(list(), integer()) :: [any()]
  defp encode_list_data(data, bolt_version) do
    Enum.map(data, &Encoder.encode(&1, bolt_version))
  end

  @spec encode_kv(map(), integer()) :: binary()
  defp encode_kv(map, bolt_version) do
    Enum.reduce(map, <<>>, fn data, acc ->
      [acc,  do_reduce_kv(data, bolt_version)]
    end)
  end

  @spec do_reduce_kv({atom(), any()}, integer()) :: binary()
  defp do_reduce_kv({key, value}, bolt_version) do
    [Encoder.encode(key, bolt_version) , Encoder.encode(value, bolt_version)]
  end

  @spec day_time(Time.t()) :: integer()
  defp day_time(time) do
    Time.diff(time, ~T[00:00:00.000], :nanosecond)
  end

  @spec decompose_datetime(Calendar.naive_datetime()) :: [integer()]
  defp decompose_datetime(%NaiveDateTime{} = datetime) do
    datetime_micros = NaiveDateTime.diff(datetime, ~N[1970-01-01 00:00:00.000], :microsecond)

    seconds = div(datetime_micros, 1_000_000)
    nanoseconds = rem(datetime_micros, 1_000_000) * 1_000

    [seconds, nanoseconds]
  end

  @spec compact_duration(Duration.t()) :: [integer()]
  defp compact_duration(%Duration{} = duration) do
    months = 12 * duration.years + duration.months
    days = 7 * duration.weeks + duration.days
    seconds = 3600 * duration.hours + 60 * duration.minutes + duration.seconds

    [months, days, seconds, duration.nanoseconds]
  end
end
