defmodule Bolt.Sips.Internals.BoltProtocol.Factory do
  @spec create_protocol(version :: float) :: module | :error
  def create_protocol(version) do
    version_float = version + 0.0
    protocol_module =
      case version_float do
        1.0 -> Bolt.Protocol.V1
        2.0 -> Bolt.Protocol.V1
        3.0 -> Bolt.Protocol.V3
        5.3 -> Bolt.Protocol.V5_0
        _ -> nil
      end

    if protocol_module != nil do
      {:ok, protocol_module}
    else
      {:error, "Protocol version #{version} is not implemented."}
    end
  end
end
