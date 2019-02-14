defmodule Bolt.Sips.TypesHelper do
  @doc """
  Decompose an amount seconds into the tuple {hours, minutes, seconds}
  """
  @spec decompose_in_hms(integer()) :: {integer(), integer(), integer()}
  def decompose_in_hms(seconds) do
    [{minutes, seconds}, {hours, _}, _] =
      [3600, 60]
      |> Enum.reduce([{0, seconds}], fn
        divisor, acc ->
          {_, num} = hd(acc)
          [{div(num, divisor), rem(num, divisor)} | acc]
      end)

    {hours, minutes, seconds}
  end

  @doc """
  Convert NaiveDateTime and timezone into a Calendar.DateTime
  Without losing micorsecond data!
  """
  @spec datetime_with_micro(Calendar.naive_datetime(), String.t()) :: Calendar.datetime()
  def datetime_with_micro(%NaiveDateTime{} = naive_dt, timezone) do
    erl_date =
      {{naive_dt.year, naive_dt.month, naive_dt.day},
       {naive_dt.hour, naive_dt.minute, naive_dt.second}}

    micros = naive_dt.microsecond

    Calendar.DateTime.from_erl!(erl_date, timezone, micros)
  end

  @doc """
  Convert an amount of seconds in a +hours:minutes offset
  """
  @spec formated_time_offset(integer()) :: String.t()
  def formated_time_offset(offset_seconds) do
    {hours, minutes, _} = offset_seconds |> abs() |> decompose_in_hms()
    get_sign_string(offset_seconds) <> format_time_part(hours) <> ":" <> format_time_part(minutes)
  end

  defp get_sign_string(number) when number >= 0 do
    "+"
  end

  defp get_sign_string(_) do
    "-"
  end

  defp format_time_part(time_part) when time_part < 10 do
    "0" <> Integer.to_string(time_part)
  end

  defp format_time_part(time_part) do
    Integer.to_string(time_part)
  end
end
