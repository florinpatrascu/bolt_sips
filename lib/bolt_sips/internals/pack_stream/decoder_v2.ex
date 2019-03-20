defmodule Bolt.Sips.Internals.PackStream.DecoderV2 do
  @moduledoc false
  _module_doc = """
  Bolt V2 has specification for decoding:
  - Temporal types:
    - Local Date
    - Local Time
    - Local DateTime
    - Time with Timezone Offset
    - DateTime with Timezone Id
    - DateTime with Timezone Offset
    - Duration
  - Spatial types:
    - Point2D
    - Point3D

  For documentation about those typs representation in Bolt binary,
  please see `Bolt.Sips.Internals.PackStream.EncoderV2`.

  Functions from this module are not meant to be used directly.
  Use `Decoder.decode(data, bolt_version)` for all decoding purposes.
  """

  use Bolt.Sips.Internals.PackStream.Markers
  alias Bolt.Sips.Internals.PackStream.Decoder
  alias Bolt.Sips.Types.{TimeWithTZOffset, DateTimeWithTZOffset, Duration, Point}

  # Local Date
  @spec decode({integer(), binary(), integer()}, integer()) :: list() | {:error, :not_implemented}
  def decode({@date_signature, struct, @date_struct_size}, bolt_version) do
    {[date], rest} = Decoder.decode_struct(struct, @date_struct_size, bolt_version)
    [Date.add(~D[1970-01-01], date) | rest]
  end

  # Local Time
  def decode({@local_time_signature, struct, @local_time_struct_size}, bolt_version) do
    {[time], rest} = Decoder.decode_struct(struct, @local_time_struct_size, bolt_version)

    [Time.add(~T[00:00:00.000], time, :nanosecond) | rest]
  end

  # Local DateTime
  def decode({@local_datetime_signature, struct, @local_datetime_struct_size}, bolt_version) do
    {[seconds, nanoseconds], rest} =
      Decoder.decode_struct(struct, @local_datetime_struct_size, bolt_version)

    ndt =
      NaiveDateTime.add(
        ~N[1970-01-01 00:00:00.000],
        seconds * 1_000_000_000 + nanoseconds,
        :nanosecond
      )

    [ndt | rest]
  end

  # Time with Zone Offset
  def decode({@time_with_tz_signature, struct, @time_with_tz_struct_size}, bolt_version) do
    {[time, offset], rest} =
      Decoder.decode_struct(struct, @time_with_tz_struct_size, bolt_version)

    t = TimeWithTZOffset.create(Time.add(~T[00:00:00.000], time, :nanosecond), offset)
    [t | rest]
  end

  # Datetime with zone Id
  def decode(
        {@datetime_with_zone_id_signature, struct, @datetime_with_zone_id_struct_size},
        bolt_version
      ) do
    {[seconds, nanoseconds, zone_id], rest} =
      Decoder.decode_struct(struct, @datetime_with_zone_id_struct_size, bolt_version)

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
        {@datetime_with_zone_offset_signature, struct, @datetime_with_zone_offset_struct_size},
        bolt_version
      ) do
    {[seconds, nanoseconds, zone_offset], rest} =
      Decoder.decode_struct(struct, @datetime_with_zone_id_struct_size, bolt_version)

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
  def decode({@duration_signature, struct, @duration_struct_size}, bolt_version) do
    {[months, days, seconds, nanoseconds], rest} =
      Decoder.decode_struct(struct, @duration_struct_size, bolt_version)

    duration = Duration.create(months, days, seconds, nanoseconds)
    [duration | rest]
  end

  # Point2D
  def decode({@point2d_signature, struct, @point2d_struct_size}, bolt_version) do
    {[srid, x, y], rest} = Decoder.decode_struct(struct, @point2d_struct_size, bolt_version)
    point = Point.create(srid, x, y)

    [point | rest]
  end

  # Point3D
  def decode({@point3d_signature, struct, @point3d_struct_size}, bolt_version) do
    {[srid, x, y, z], rest} = Decoder.decode_struct(struct, @point3d_struct_size, bolt_version)
    point = Point.create(srid, x, y, z)

    [point | rest]
  end

  def decode(_, _) do
    {:error, :not_implemented}
  end
end
