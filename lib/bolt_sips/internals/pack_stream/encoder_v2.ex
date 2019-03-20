defmodule Bolt.Sips.Internals.PackStream.EncoderV2 do
  @moduledoc false
  use Bolt.Sips.Internals.PackStream.Markers
  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Types.{TimeWithTZOffset, DateTimeWithTZOffset, Duration, Point}

  @doc """
  Encode a Time (represented by Time) into Bolt binary format.
  Encoded in a structure.

  Signature: `0x74`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Nanoseconds_from_00:00:00`

  ## Example

      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_local_time(~T[06:54:32.453], 2)
      <<0xB1, 0x74, 0xCB, 0x0, 0x0, 0x16, 0x9F, 0x11, 0xB9, 0xCB, 0x40>>
  """
  @spec encode_local_time(Time.t(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_local_time(local_time, bolt_version) do
    Encoder.encode({@local_time_signature, [day_time(local_time)]}, bolt_version)
  end

  @doc """
  Encode a TIME WITH TIMEZONE OFFSET (represented by TimeWithTZOffset) into Bolt binary format.
  Encoded in a structure.

  Signature: `0x54`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Nanoseconds_from_00:00:00` `Offset_in_seconds`

  ## Example

      iex> time_with_tz = Bolt.Sips.Types.TimeWithTZOffset.create(~T[06:54:32.453], 3600)
      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_time_with_tz(time_with_tz, 2)
      <<0xB2, 0x54, 0xCB, 0x0, 0x0, 0x16, 0x9F, 0x11, 0xB9, 0xCB, 0x40, 0xC9, 0xE, 0x10>>
  """
  def encode_time_with_tz(%TimeWithTZOffset{time: time, timezone_offset: offset}, bolt_version) do
    Encoder.encode({@time_with_tz_signature, [day_time(time), offset]}, bolt_version)
  end

  @spec day_time(Time.t()) :: integer()
  defp day_time(time) do
    Time.diff(time, ~T[00:00:00.000], :nanosecond)
  end

  @doc """
  Encode a DATE (represented by Date) into Bolt binary format.
  Encoded in a structure.

  Signature: `0x44`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Nb_days_since_epoch`

  ## Example

      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_date(~D[2019-04-23], 2)
      <<0xB1, 0x44, 0xC9, 0x46, 0x59>>

  """
  @spec encode_date(Date.t(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_date(date, bolt_version) do
    epoch = Date.diff(date, ~D[1970-01-01])

    Encoder.encode({@date_signature, [epoch]}, bolt_version)
  end

  @doc """
  Encode a LOCAL DATETIME (Represented by NaiveDateTime) into Bolt binary format.
  Encoded in a structure.

  WARNING: Nanoseconds are left off as NaiveDateTime doesn't handle them.
  A new Calendar should be implemented to manage them.

  Signature: `0x64`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Nb_seconds_since_epoch` `Remainder_in_nanoseconds`

  ## Example

      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_local_datetime(~N[2019-04-23 13:45:52.678], 2)
      <<0xB2, 0x64, 0xCA, 0x5C, 0xBF, 0x17, 0x10, 0xCA, 0x28, 0x69, 0x75, 0x80>>

  """
  @spec encode_local_datetime(Calendar.naive_datetime(), integer()) ::
          Bolt.Sips.Internals.PackStream.value()
  def encode_local_datetime(local_datetime, bolt_version) do
    Encoder.encode({@local_datetime_signature, decompose_datetime(local_datetime)}, bolt_version)
  end

  @doc """
  Encode DATETIME WITH TIMEZONE ID (represented by Calendar.DateTime) into Bolt binary format.
  Encoded in a structure.

  WARNING: Nanoseconds are left off as NaiveDateTime doesn't handle them.
  A new Calendar should be implemented to manage them.

  Signature: `0x66`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Nb_seconds_since_epoch` `Remainder_in_nanoseconds` `Zone_id`

  ## Example

      iex> d = Bolt.Sips.TypesHelper.datetime_with_micro(~N[2013-11-12 07:32:02.003],
      ...> "Europe/Berlin")
      #DateTime<2013-11-12 07:32:02.003+01:00 CET Europe/Berlin>
      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_datetime_with_tz_id(d, 2)
      <<0xB3, 0x66, 0xCA, 0x52, 0x81, 0xD9, 0x72, 0xCA, 0x0, 0x2D, 0xC6, 0xC0, 0x8D, 0x45, 0x75,
      0x72, 0x6F, 0x70, 0x65, 0x2F, 0x42, 0x65, 0x72, 0x6C, 0x69, 0x6E>>

  """
  @spec encode_datetime_with_tz_id(Calendar.datetime(), integer()) ::
          Bolt.Sips.Internals.PackStream.value()
  def encode_datetime_with_tz_id(datetime, bolt_version) do
    data = decompose_datetime(DateTime.to_naive(datetime)) ++ [datetime.time_zone]

    Encoder.encode({@datetime_with_zone_id_signature, data}, bolt_version)
  end

  @doc """
  Encode DATETIME WITH TIMEZONE OFFSET (represented by DateTimeWithTZOffset) into Bolt binary format.
  Encoded in a structure.

  WARNING: Nanoseconds are left off as NaiveDateTime doesn't handle them.
  A new Calendar should be implemented to manage them.

  Signature: `0x46`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Nb_seconds_since_epoch` `Remainder_in_nanoseconds` `Zone_offset`

  ## Example

      iex> d = Bolt.Sips.Types.DateTimeWithTZOffset.create(~N[2013-11-12 07:32:02.003], 7200)
      %Bolt.Sips.Types.DateTimeWithTZOffset{
              naive_datetime: ~N[2013-11-12 07:32:02.003],
              timezone_offset: 7200
            }
      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_datetime_with_tz_offset(d, 2)
      <<0xB3, 0x46, 0xCA, 0x52, 0x81, 0xD9, 0x72, 0xCA, 0x0, 0x2D, 0xC6, 0xC0, 0xC9, 0x1C, 0x20>>

  """
  @spec encode_datetime_with_tz_offset(DateTimeWithTZOffset.t(), integer()) ::
          Bolt.Sips.Internals.PackStream.value()
  def encode_datetime_with_tz_offset(
        %DateTimeWithTZOffset{naive_datetime: ndt, timezone_offset: tz_offset},
        bolt_version
      ) do
    data = decompose_datetime(ndt) ++ [tz_offset]
    Encoder.encode({@datetime_with_zone_offset_signature, data}, bolt_version)
  end

  @spec decompose_datetime(Calendar.naive_datetime()) :: [integer()]
  defp decompose_datetime(%NaiveDateTime{} = datetime) do
    datetime_micros = NaiveDateTime.diff(datetime, ~N[1970-01-01 00:00:00.000], :microsecond)

    seconds = div(datetime_micros, 1_000_000)
    nanoseconds = rem(datetime_micros, 1_000_000) * 1_000

    [seconds, nanoseconds]
  end

  @doc """
  Encode DURATION (represented by Duration) into Bolt binary format.
  Encoded in a structure.

  Signature: `0x45`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `Months` `Days` `Seconds` `Nanoseconds`

  ## Example

      iex(60)> d = %Bolt.Sips.Types.Duration{
      ...(60)>   years: 3,
      ...(60)>   months: 1,
      ...(60)>   weeks: 7,
      ...(60)>   days: 4,
      ...(60)>   hours: 13,
      ...(60)>   minutes: 2,
      ...(60)>   seconds: 21,
      ...(60)>   nanoseconds: 554
      ...(60)> }
      %Bolt.Sips.Types.Duration{
        days: 4,
        hours: 13,
        minutes: 2,
        months: 1,
        nanoseconds: 554,
        seconds: 21,
        weeks: 7,
        years: 3
      }
      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_duration(d, 2)
      <<0xB4, 0x45, 0x25, 0x35, 0xCA, 0x0, 0x0, 0xB7, 0x5D, 0xC9, 0x2, 0x2A>>
  """
  @spec encode_duration(Duration.t(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_duration(%Duration{} = duration, bolt_version) do
    Encoder.encode({@duration_signature, compact_duration(duration)}, bolt_version)
  end

  @spec compact_duration(Duration.t()) :: [integer()]
  defp compact_duration(%Duration{} = duration) do
    months = 12 * duration.years + duration.months
    days = 7 * duration.weeks + duration.days
    seconds = 3600 * duration.hours + 60 * duration.minutes + duration.seconds

    [months, days, seconds, duration.nanoseconds]
  end

  @doc """
  Encode POINT 2D & 3D (represented by Point) into Bolt binary format.
  Encoded in a structure.


  ## Point 2D
  Signature: `0x58`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `SRID` `x_or_longitude` `y_or_latitude`

  ## Example

      iex> p = Bolt.Sips.Types.Point.create(:wgs_84, 65.43, 12.54)
      %Bolt.Sips.Types.Point{
              crs: "wgs-84",
              height: nil,
              latitude: 12.54,
              longitude: 65.43,
              srid: 4326,
              x: 65.43,
              y: 12.54,
              z: nil
            }
      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_point(p, 2)
      <<0xB3, 0x58, 0xC9, 0x10, 0xE6, 0xC1, 0x40, 0x50, 0x5B, 0x85, 0x1E, 0xB8, 0x51, 0xEC, 0xC1,
      0x40, 0x29, 0x14, 0x7A, 0xE1, 0x47, 0xAE, 0x14>>

  ## Point 3D
  Signature: `0x58`

  Encoding:
  `Marker` `Size` `Signature` ` Content`

  where `Content` is:
  `SRID` `x_or_longitude` `y_or_latitude` `z_or_height`

  ## Example

      iex> p = Bolt.Sips.Types.Point.create(:wgs_84, 45.0003, 40.3245, 23.1)
      %Bolt.Sips.Types.Point{
              crs: "wgs-84-3d",
              height: 23.1,
              latitude: 40.3245,
              longitude: 45.0003,
              srid: 4979,
              x: 45.0003,
              y: 40.3245,
              z: 23.1
            }
      iex> Bolt.Sips.Internals.PackStream.EncoderV2.encode_point(p, 2)
      <<0xB4, 0x59, 0xC9, 0x13, 0x73, 0xC1, 0x40, 0x46, 0x80, 0x9, 0xD4, 0x95, 0x18, 0x2B, 0xC1,
      0x40, 0x44, 0x29, 0x89, 0x37, 0x4B, 0xC6, 0xA8, 0xC1, 0x40, 0x37, 0x19, 0x99, 0x99, 0x99,
      0x99, 0x9A>>

  """
  @spec encode_point(Point.t(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_point(%Point{z: nil} = point, bolt_version) do
    Encoder.encode({@point2d_signature, [point.srid, point.x, point.y]}, bolt_version)
  end

  def encode_point(%Point{} = point, bolt_version) do
    Encoder.encode({@point3d_signature, [point.srid, point.x, point.y, point.z]}, bolt_version)
  end
end
