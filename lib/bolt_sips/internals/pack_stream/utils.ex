defmodule Bolt.Sips.Internals.PackStream.Utils do
  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Types.Duration
  alias Bolt.Sips.Internals.PackStreamError

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      # catch all clause for encoding implementation
      defp do_call_encode(data_type, data, original_version) do
        raise PackStreamError,
          data_type: data_type,
          data: data,
          bolt_version: original_version,
          message: "Encoding function not implemented for"
      end

      @spec encode_list_data(list(), integer()) :: [any()]
      defp encode_list_data(data, bolt_version) do
        Enum.map(
          data,
          &Encoder.encode(&1, bolt_version)
        )
      end

      @spec encode_kv(map(), integer()) :: binary()
      defp encode_kv(map, bolt_version) do
        Enum.reduce(map, <<>>, fn data, acc -> [acc, do_reduce_kv(data, bolt_version)] end)
      end

      @spec do_reduce_kv({atom(), any()}, integer()) :: [binary()]
      defp do_reduce_kv({key, value}, bolt_version) do
        [
          Encoder.encode(
            key,
            bolt_version
          ),
          Encoder.encode(value, bolt_version)
        ]
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
  end
end
