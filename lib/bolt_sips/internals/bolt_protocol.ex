defmodule Bolt.Sips.Internals.BoltProtocol do
  @moduledoc false
  # A library that handles Bolt Protocol (v1 and v2).
  # Note that for now, only Neo4j implements Bolt v2.

  # It handles all the protocol specific steps (i.e.
  # handshake, init) as well as sending and receiving messages and wrapping
  # them in chunks.

  # It abstracts transportation, expecting the transport layer to define
  # `send/2` and `recv/3` analogous to `:gen_tcp`.

  # ## Logging configuration
  # Logging can be enable / disable via config files (e.g, `config/config.exs`).
  #   - `:log`: (bool) wether Bolt.Sips.Internals. should produce logs or not. Defaults to `false`
  #   - `:log_hex`: (bool) wether Bolt.Sips.Internals. should produce logs hexadecimal counterparts. While this may be interesting,
  #   note that all the hexadecimal data will be written and this can be very long, and thus can seriously impact performances. Defaults to `false`

  # For example, configuration to see the logs and their hexadecimal counterparts:
  # ```
  #   config :Bolt.Sips.Internals.,
  #     log: true,
  #     log_hex: true
  # ```
  #   # #### Examples of logging (without log_hex)

  #     iex> Bolt.Sips.Internals.test('localhost', 7687, "RETURN 1 as num", %{}, {"neo4j", "password"})
  #     C: HANDSHAKE ~ "<<0x60, 0x60, 0xB0, 0x17>> [2, 1, 0, 0]"
  #     S: HANDSHAKE ~ 2
  #     C: INIT ~ ["BoltSips/1.1.0.rc2", %{credentials: "password", principal: "neo4j", scheme: "basic"}]
  #     S: SUCCESS ~ %{"server" => "Neo4j/3.4.1"}
  #     C: RUN ~ ["RETURN 1 as num", %{}]
  #     S: SUCCESS ~ %{"fields" => ["num"], "result_available_after" => 1}
  #     C: PULL_ALL ~ []
  #     S: RECORD ~ [1]
  #     S: SUCCESS ~ %{"result_consumed_after" => 0, "type" => "r"}
  #     [
  #       success: %{"fields" => ["num"], "result_available_after" => 1},
  #       record: [1],
  #       success: %{"result_consumed_after" => 0, "type" => "r"}
  #     ]

  # #### Examples of logging (with log_hex)

  #     iex> Bolt.Sips.Internals.test('localhost', 7687, "RETURN 1 as num", %{}, {"neo4j", "password"})
  #     13:32:23.882 [debug] C: HANDSHAKE ~ "<<0x60, 0x60, 0xB0, 0x17>> [2, 1, 0, 0]"
  #     S: HANDSHAKE ~ <<0x0, 0x0, 0x0, 0x2>>
  #     S: HANDSHAKE ~ 2
  #     C: INIT ~ ["BoltSips/1.1.0.rc2", %{credentials: "password", principal: "neo4j", scheme: "basic"}]
  #     C: INIT ~ <<0x0, 0x42, 0xB2, 0x1, 0x8C, 0x42, 0x6F, 0x6C, 0x74, 0x65, 0x78, 0x2F, 0x30, 0x2E, 0x35, 0x2E, 0x30, 0xA3, 0x8B, 0x63, 0x72, 0x65, 0x64, 0x65, 0x6E, 0x74, 0x69, 0x61, 0x6C, 0x73, 0x88, 0x70, 0x61, 0x73, 0x73, 0x77, 0x6F, 0x72, 0x64, 0x89, 0x70, 0x72, 0x69, 0x6E, 0x63, 0x69, 0x70, 0x61, 0x6C, 0x85, 0x6E, 0x65, 0x6F, 0x34, 0x6A, 0x86, 0x73, 0x63, 0x68, 0x65, 0x6D, 0x65, 0x85, 0x62, 0x61, 0x73, 0x69, 0x63, 0x0, 0x0>>
  #     S: SUCCESS ~ <<0xA1, 0x86, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x8B, 0x4E, 0x65, 0x6F, 0x34, 0x6A, 0x2F, 0x33, 0x2E, 0x34, 0x2E, 0x31>>
  #     S: SUCCESS ~ %{"server" => "Neo4j/3.4.1"}
  #     C: RUN ~ ["RETURN 1 as num", %{}]
  #     C: RUN ~ <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x31, 0x20, 0x61, 0x73, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0, 0x0>>
  #     S: SUCCESS ~ <<0xA2, 0xD0, 0x16, 0x72, 0x65, 0x73, 0x75, 0x6C, 0x74, 0x5F, 0x61, 0x76, 0x61, 0x69, 0x6C, 0x61, 0x62, 0x6C, 0x65, 0x5F, 0x61, 0x66, 0x74, 0x65, 0x72, 0x1, 0x86, 0x66, 0x69, 0x65, 0x6C, 0x64, 0x73, 0x91, 0x83, 0x6E, 0x75, 0x6D>>
  #     S: SUCCESS ~ %{"fields" => ["num"], "result_available_after" => 1}
  #     C: PULL_ALL ~ []
  #     C: PULL_ALL ~ <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>>
  #     S: RECORD ~ <<0x91, 0x1>>
  #     S: RECORD ~ [1]
  #     S: SUCCESS ~ <<0xA2, 0xD0, 0x15, 0x72, 0x65, 0x73, 0x75, 0x6C, 0x74, 0x5F, 0x63, 0x6F, 0x6E, 0x73, 0x75, 0x6D, 0x65, 0x64, 0x5F, 0x61, 0x66, 0x74, 0x65, 0x72, 0x0, 0x84, 0x74, 0x79, 0x70, 0x65, 0x81, 0x72>>
  #     S: SUCCESS ~ %{"result_consumed_after" => 0, "type" => "r"}
  #     [
  #       success: %{"fields" => ["num"], "result_available_after" => 1},
  #       record: [1],
  #       success: %{"result_consumed_after" => 0, "type" => "r"}
  #     ]

  # ## Shared options

  # Functions that allow for options accept these default options:

  #   * `recv_timeout`: The timeout for receiving a response from the Neo4J s
  #     server (default: #{@recv_timeout})

  alias Bolt.Sips.Internals.BoltProtocolV1

  defdelegate handshake(transport, port, options \\ []), to: BoltProtocolV1
  defdelegate init(transport, port, version, auth \\ {}, options \\ []), to: BoltProtocolV1

  defdelegate ack_failure(transport, port, bolt_version, options \\ []), to: BoltProtocolV1
  defdelegate reset(transport, port, bolt_version, options \\ []), to: BoltProtocolV1
  defdelegate discard_all(transport, port, bolt_version, options \\ []), to: BoltProtocolV1

  defdelegate run(transport, port, bolt_version, statement, params \\ %{}, options \\ []),
    to: BoltProtocolV1

  defdelegate pull_all(transport, port, bolt_version, options \\ []), to: BoltProtocolV1

  defdelegate run_statement(
                transport,
                port,
                bolt_version,
                statement,
                params \\ %{},
                options \\ []
              ),
              to: BoltProtocolV1
end
