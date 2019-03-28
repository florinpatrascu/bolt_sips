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

  alias Bolt.Sips.Metadata
  alias Bolt.Sips.Internals.BoltProtocolV1
  alias Bolt.Sips.Internals.BoltProtocolV3

  defdelegate handshake(transport, port, options \\ []), to: BoltProtocolV1
  defdelegate init(transport, port, version, auth \\ {}, options \\ []), to: BoltProtocolV1
  defdelegate hello(transport, port, version, auth \\ {}, options \\ []), to: BoltProtocolV3
  defdelegate goodbye(transport, port, version), to: BoltProtocolV3

  defdelegate ack_failure(transport, port, bolt_version, options \\ []), to: BoltProtocolV1
  defdelegate reset(transport, port, bolt_version, options \\ []), to: BoltProtocolV1
  defdelegate discard_all(transport, port, bolt_version, options \\ []), to: BoltProtocolV1

  defdelegate begin(transport, port, bolt_version, metadata \\ %Metadata{}, options \\ []),
    to: BoltProtocolV3

  defdelegate commit(transport, port, bolt_version, options \\ []), to: BoltProtocolV3
  defdelegate rollback(transport, port, bolt_version, options \\ []), to: BoltProtocolV3

  defdelegate pull_all(transport, port, bolt_version, options \\ []), to: BoltProtocolV1

  @doc """
  run for all Bolt version, but call differs.
  For Bolt <= 2, use: run_statement(transport, port, bolt_version, statement, params, options)
  For Bolt >=3: run_statement(transport, port, bolt_version, statement, params, metadata, options)

  Note that Bolt V2 calls works with Bolt V3, but it is preferrable to update them.
  """
  @spec run(
          atom(),
          port(),
          integer(),
          String.t(),
          map(),
          nil | Keyword.t() | Bolt.Sips.Metadata.t(),
          nil | Keyword.t()
        ) ::
          {:ok, tuple()}
          | Bolt.Sips.Internals.Error.t()
  def run(
        transport,
        port,
        bolt_version,
        statement,
        params \\ %{},
        options_or_metadata \\ [],
        options \\ []
      )

  def run(transport, port, bolt_version, statement, params, options_or_metadata, _)
      when bolt_version <= 2 do
    BoltProtocolV1.run(
      transport,
      port,
      bolt_version,
      statement,
      params,
      options_or_metadata || []
    )
  end

  def run(transport, port, bolt_version, statement, params, metadata, options)
      when bolt_version >= 2 do
    metadata =
      case metadata do
        [] -> %{}
        metadata -> metadata
      end

    {metadata, options} = manage_metadata_and_options(metadata, options)

    BoltProtocolV3.run(transport, port, bolt_version, statement, params, metadata, options)
  end

  defp manage_metadata_and_options([], options) do
    {:ok, empty_metadata} = Metadata.new(%{})
    {empty_metadata, options}
  end

  defp manage_metadata_and_options([_ | _] = metadata, options) do
    {:ok, empty_metadata} = Metadata.new(%{})
    {empty_metadata, metadata ++ options}
  end

  defp manage_metadata_and_options(metadata, options) do
    {metadata, options}
  end

  @doc """
  run_statement for all Bolt version, but call differs.
  For Bolt <= 2, use: run_statement(transport, port, bolt_version, statement, params, options)
  For Bolt >=3: run_statement(transport, port, bolt_version, statement, params, metadata, options)

  Note that Bolt V2 calls works with Bolt V3, but it is preferrable to update them.
  """
  @spec run_statement(
          atom(),
          port(),
          integer(),
          String.t(),
          map(),
          nil | Keyword.t() | Bolt.Sips.Metadata.t(),
          nil | Keyword.t()
        ) ::
          list()
          | Bolt.Sips.Internals.Error.t()
  def run_statement(
        transport,
        port,
        bolt_version,
        statement,
        params \\ %{},
        options_v2_or_metadata_v3 \\ [],
        options_v3 \\ []
      )

  def run_statement(transport, port, bolt_version, statement, params, options_or_metadata, _)
      when bolt_version <= 2 do
    BoltProtocolV1.run_statement(
      transport,
      port,
      bolt_version,
      statement,
      params,
      options_or_metadata || []
    )
  end

  def run_statement(transport, port, bolt_version, statement, params, metadata, options)
      when bolt_version >= 2 do
    metadata =
      case metadata do
        [] -> %{}
        metadata -> metadata
      end

    BoltProtocolV3.run_statement(
      transport,
      port,
      bolt_version,
      statement,
      params,
      metadata,
      options
    )
  end
end
