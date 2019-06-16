defmodule Bolt.Sips.ConnectionSupervisor do
  @moduledoc """

  """

  use DynamicSupervisor

  alias Bolt.Sips.Protocol
  alias Bolt.Sips

  require Logger
  # @type via :: {:via, Registry, any}
  @name __MODULE__

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: @name)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  the resulting connection name i.e. "write@localhost:7687" will be used to spawn new
  DBConnection processes, and for finding available connections
  """
  def start_child(role, url, config) do
    prefix = Keyword.get(config, :prefix, :default)

    connection_name = "#{prefix}_#{role}@#{url}"

    role_config =
      config
      |> Keyword.put(:role, role)
      |> Keyword.put(:name, via_tuple(connection_name))

    spec = %{
      id: connection_name,
      start: {DBConnection, :start_link, [Protocol, role_config]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }

    # [Protocol, role_config];
    with {:error, :not_found} <- find_connection(connection_name),
         {:ok, _pid} = r <- DynamicSupervisor.start_child(@name, spec) do
      [spec, r]

      r
    else
      {:ok, pid, _info} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      pid -> {:ok, pid}
    end
  end

  @spec find_connection(atom, String.t(), atom) :: {:error, :not_found} | {:ok, pid()}
  def find_connection(role, url, prefix), do: find_connection("#{prefix}_#{role}@#{url}")

  @spec find_connection(any()) :: {:error, :not_found} | {:ok, pid()}
  def find_connection(name) do
    case Registry.lookup(Sips.registry_name(), name) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  @spec terminate_connection(atom, String.t(), atom) :: {:error, :not_found} | {:ok, pid()}
  def terminate_connection(role, url, prefix \\ :default) do
    with {:ok, pid} = r <- find_connection(role, url, prefix),
         true <- Process.exit(pid, :normal) do
      connections()
      r
    end
  end

  def connections() do
    _connections()
    |> Enum.map(fn pid ->
      Sips.registry_name()
      |> Registry.keys(pid)
      |> List.first()
    end)
  end

  defp _connections() do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.filter(fn {_, pid, _type, modules} ->
      case {pid, modules} do
        {:restarting, _} -> false
        {_pid, _} -> true
      end
    end)
    |> Enum.map(fn {_, pid, _, _} ->
      pid
    end)
  end

  def via_tuple(name) do
    {:via, Registry, {Bolt.Sips.registry_name(), name}}
  end
end
