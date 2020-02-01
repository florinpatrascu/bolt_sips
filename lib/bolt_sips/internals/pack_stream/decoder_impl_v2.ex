defmodule Bolt.Sips.Internals.PackStream.DecoderImplV2 do
  alias Bolt.Sips.Types.{TimeWithTZOffset, DateTimeWithTZOffset, Duration, Point}

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      @last_version Bolt.Sips.Internals.BoltVersionHelper.last()

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

      # Local Date
      def decode({@date_signature, struct, @date_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[date], rest} = decode_struct(struct, @date_struct_size, bolt_version)
        [Date.add(~D[1970-01-01], date) | rest]
      end

      # Local Time
      def decode({@local_time_signature, struct, @local_time_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[time], rest} = decode_struct(struct, @local_time_struct_size, bolt_version)

        [Time.add(~T[00:00:00.000], time, :nanosecond) | rest]
      end

      # Local DateTime
      def decode({@local_datetime_signature, struct, @local_datetime_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[seconds, nanoseconds], rest} =
          decode_struct(struct, @local_datetime_struct_size, bolt_version)

        ndt =
          NaiveDateTime.add(
            ~N[1970-01-01 00:00:00.000],
            seconds * 1_000_000_000 + nanoseconds,
            :nanosecond
          )

        [ndt | rest]
      end

      # Time with Zone Offset
      def decode({@time_with_tz_signature, struct, @time_with_tz_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[time, offset], rest} = decode_struct(struct, @time_with_tz_struct_size, bolt_version)

        t = TimeWithTZOffset.create(Time.add(~T[00:00:00.000], time, :nanosecond), offset)
        [t | rest]
      end

      # Datetime with zone Id
      def decode(
            {@datetime_with_zone_id_signature, struct, @datetime_with_zone_id_struct_size},
            bolt_version
          )
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[seconds, nanoseconds, zone_id], rest} =
          decode_struct(struct, @datetime_with_zone_id_struct_size, bolt_version)

        naive_dt =
          NaiveDateTime.add(
            ~N[1970-01-01 00:00:00.000],
            seconds * 1_000_000_000 + nanoseconds,
            :nanosecond
          )

        dt = Bolt.Sips.TypesHelper.datetime_with_micro(naive_dt, zone_id)
        [dt | rest]
      end

      # Datetime with zone offset
      def decode(
            {@datetime_with_zone_offset_signature, struct,
             @datetime_with_zone_offset_struct_size},
            bolt_version
          )
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[seconds, nanoseconds, zone_offset], rest} =
          decode_struct(struct, @datetime_with_zone_id_struct_size, bolt_version)

        naive_dt =
          NaiveDateTime.add(
            ~N[1970-01-01 00:00:00.000],
            seconds * 1_000_000_000 + nanoseconds,
            :nanosecond
          )

        dt = DateTimeWithTZOffset.create(naive_dt, zone_offset)
        [dt | rest]
      end

      # Duration
      def decode({@duration_signature, struct, @duration_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[months, days, seconds, nanoseconds], rest} =
          decode_struct(struct, @duration_struct_size, bolt_version)

        duration = Duration.create(months, days, seconds, nanoseconds)
        [duration | rest]
      end

      # Point2D
      def decode({@point2d_signature, struct, @point2d_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[srid, x, y], rest} = decode_struct(struct, @point2d_struct_size, bolt_version)
        point = Point.create(srid, x, y)

        [point | rest]
      end

      # Point3D
      def decode({@point3d_signature, struct, @point3d_struct_size}, bolt_version)
          when bolt_version >= 2 and bolt_version <= @last_version do
        {[srid, x, y, z], rest} = decode_struct(struct, @point3d_struct_size, bolt_version)
        point = Point.create(srid, x, y, z)

        [point | rest]
      end
    end
  end
end
