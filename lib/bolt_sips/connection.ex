defmodule Bolt.Sips.Connection do
  @moduledoc false
  use DBConnection
  alias Bolt.Sips.Client
  alias Bolt.Sips.Internals.Error, as: BoltError

  defstruct [
    :client,
    :bolt_version,
    :server_version
  ]

  @impl true
  def connect(opts) do
    config = Client.Config.new(opts)
    with {:ok, %Client{} = client} <- Client.connect(config),
         {:ok, server_version} <- do_init(client, opts) do
        state = %__MODULE__{
          client: client,
          server_version: server_version,
          bolt_version: client.bolt_version
        }
        {:ok, state}
      else
        {:error, reason} ->
          {:error, BoltError.exception(reason, nil, :connect)}
    end
  end

  defp do_init(client, opts) do
    do_init(client.bolt_version, client, opts)
  end

  defp do_init(bolt_version, client, opts) when is_float(bolt_version) and bolt_version >= 3.0 do
    case Client.message_hello(client, opts) do
      {:ok, response} ->
        {:ok, response["server"]}
      {:error, response} ->
        {:error, response}
    end
  end

  defp do_init(bolt_version, client, opts) when is_float(bolt_version) and bolt_version <= 2.0 do
    case Client.message_init(client, opts) do
      {:ok, response} ->
        {:ok, response["server"]}
      {:error, response} ->
        {:error, response}
    end
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
