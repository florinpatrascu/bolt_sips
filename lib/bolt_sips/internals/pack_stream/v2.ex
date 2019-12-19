defmodule Bolt.Sips.Internals.PackStream.V2 do
  alias Bolt.Sips.Types.{TimeWithTZOffset, DateTimeWithTZOffset, Duration, Point}
  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Internals.PackStreamError

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      @last_version Bolt.Sips.Internals.BoltVersionHelper.last()

      # Local Time
      @local_time_signature 0x74

      # Time With TZ Offset
      @time_with_tz_signature 0x54

      # Date
      @date_signature 0x44

      # Local DateTime
      @local_datetime_signature 0x64

      # Datetime with TZ offset
      @datetime_with_zone_offset_signature 0x46

      # Datetime with TZ id
      @datetime_with_zone_id_signature 0x66

      # Duration
      @duration_signature 0x45

      # Point 2D
      @point2d_signature 0x58

      # Point 3D
      @point3d_signature 0x59
      defp do_call_encode(:local_time, local_time, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        Encoder.encode({@local_time_signature, [day_time(local_time)]}, bolt_version)
      end

      defp do_call_encode(
             :time_with_tz,
             %TimeWithTZOffset{time: time, timezone_offset: offset},
             bolt_version
           )
           when bolt_version >= 2 and bolt_version <= @last_version do
        Encoder.encode({@time_with_tz_signature, [day_time(time), offset]}, bolt_version)
      end

      defp do_call_encode(:date, date, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        epoch = Date.diff(date, ~D[1970-01-01])

        Encoder.encode({@date_signature, [epoch]}, bolt_version)
      end

      defp do_call_encode(:local_datetime, local_datetime, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        Encoder.encode(
          {@local_datetime_signature, decompose_datetime(local_datetime)},
          bolt_version
        )
      end

      defp do_call_encode(:datetime_with_tz_id, datetime, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        data = decompose_datetime(DateTime.to_naive(datetime)) ++ [datetime.time_zone]

        Encoder.encode({@datetime_with_zone_id_signature, data}, bolt_version)
      end

      defp do_call_encode(
             :datetime_with_tz_offset,
             %DateTimeWithTZOffset{naive_datetime: ndt, timezone_offset: tz_offset},
             bolt_version
           )
           when bolt_version >= 2 and bolt_version <= @last_version do
        data = decompose_datetime(ndt) ++ [tz_offset]
        Encoder.encode({@datetime_with_zone_offset_signature, data}, bolt_version)
      end

      defp do_call_encode(:duration, %Duration{} = duration, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        Encoder.encode({@duration_signature, compact_duration(duration)}, bolt_version)
      end

      defp do_call_encode(:point, %Point{z: nil} = point, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        Encoder.encode({@point2d_signature, [point.srid, point.x, point.y]}, bolt_version)
      end

      defp do_call_encode(:point, %Point{} = point, bolt_version)
           when bolt_version >= 2 and bolt_version <= @last_version do
        Encoder.encode(
          {@point3d_signature, [point.srid, point.x, point.y, point.z]},
          bolt_version
        )
      end

    end
  end
end
