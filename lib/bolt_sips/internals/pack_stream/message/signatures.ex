defmodule Bolt.Sips.Internals.PackStream.Message.Signatures do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      # Message OUT
      @ack_failure_signature 0x0E
      @begin_signature 0x11
      @commit_signature 0x12
      @discard_all_signature 0x2F
      @goodbye_signature 0x02
      @hello_signature 0x01
      @init_signature 0x01
      @pull_all_signature 0x3F
      @reset_signature 0x0F
      @rollback_signature 0x13
      @run_signature 0x10

      # Message IN
      @success_signature 0x70
      @failure_signature 0x7F
      @record_signature 0x71
      @ignored_signature 0x7E
    end
  end
end
