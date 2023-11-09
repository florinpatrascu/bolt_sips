defmodule Bolt.Sips.Connection do
  @moduledoc false
  use DBConnection
  alias Bolt.Sips.Client
  alias Bolt.Sips.Internals.Error, as: BoltError

  defstruct [
    :client,
    :server_version,
    :hints,
    :patch_bolt
  ]

  @impl true
  def connect(opts) do
    config = Client.Config.new(opts)
    with {:ok, %Client{} = client} <- Client.connect(config),
         {:ok, response_server_metadata} <- do_init(client, opts) do
          state = getServerMetadataState(response_server_metadata)
          connection_id = getConnectionId(response_server_metadata)
          client = %Client{client | connection_id: connection_id }
          state = %__MODULE__{state | client: client}
          {:ok, state}
      else
        {:error, reason} ->
          # TODO: Evaluate how to return errors
          #{:error, BoltError.exception(reason, nil, :connect)}
          {:error, reason}
    end
  end

  defp do_init(client, opts) do
    do_init(client.bolt_version, client, opts)
  end

  defp do_init(bolt_version, client, opts) when is_float(bolt_version) and bolt_version >= 5.1 do
    with {:ok, response_hello} <- Client.message_hello(client, opts),
         {:ok, _response_logon} <- Client.message_logon(client, opts) do
          {:ok, response_hello}
        else
          {:error, reason} ->
            # TODO: Evaluate how to return errors
            #{:error, BoltError.exception(reason, nil, :do_init)}
            {:error, reason}
    end
  end

  defp do_init(bolt_version, client, opts) when is_float(bolt_version) and bolt_version >= 3.0 do
    Client.message_hello(client, opts)
  end

  defp do_init(bolt_version, client, opts) when is_float(bolt_version) and bolt_version <= 2.0 do
    Client.message_init(client, opts)
  end

  defp getServerMetadataState(response_metadata) do
    patch_bolt = get_in(response_metadata, ["patch_bolt"])
    hints = get_in(response_metadata, ["hints"])
    %__MODULE__{
      client: nil,
      server_version: response_metadata["server"],
      patch_bolt: patch_bolt,
      hints: hints
    }
  end

  defp getConnectionId(response_metadata) do
    get_in(response_metadata, ["connection_id"])
  end

  @impl true
  def disconnect(_reason, state) do
    Client.disconnect(state.client)
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def ping(state) do
    {:ok, state}
  end

  @doc "Callback for DBConnection.checkin/1"
  def checkin(state) do
    case Client.disconnect(state.client) do
      :ok -> {:ok, state}
    end
  end

  @impl true
  def handle_prepare(query, _opts, state), do: {:ok, query, state}
  @impl true
  def handle_close(query, _opts, state), do: {:ok, query, state}
  @impl true
  def handle_deallocate(query, _cursor, _opts, state), do: {:ok, query, state}
  @impl true
  def handle_declare(query, _params, _opts, state), do: {:ok, query, state, nil}
  @impl true
  def handle_fetch(query, _cursor, _opts, state), do: {:cont, query, state}
  @impl true
  def handle_status(_opts, state), do: {:idle, state}
end
