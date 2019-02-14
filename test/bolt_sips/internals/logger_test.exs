defmodule Bolt.Sips.Internals.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Bolt.Sips.Internals.Logger

  test "Log from formed message" do
    assert capture_log(fn -> Logger.log_message(:client, {:success, %{data: "ok"}}) end) =~
             "C: SUCCESS ~ %{data: \"ok\"}"
  end

  test "Log from non-formed message" do
    assert capture_log(fn -> Logger.log_message(:client, :success, %{data: "ok"}) end) =~
             "C: SUCCESS ~ %{data: \"ok\"}"
  end

  # Excluded as another test has a long result and therefore a long hex and slow down tests
  # test "Log hex data" do
  #   assert capture_log(fn -> Logger.log_message(:client, :success, <<0x01, 0xAF>>, :hex) end) =~
  #            "C: SUCCESS ~ <<0x1, 0xAF>>"
  # end
end
