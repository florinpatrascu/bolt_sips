defmodule Bolt.Sips.Internals.BoltProtocolV3 do
  alias Bolt.Sips.Internals.BoltProtocol
  alias Bolt.Sips.Internals.BoltProtocolHelper
  alias Bolt.Sips.Internals.Error

  @doc """
  Implementation of Bolt's HELLO. It initialises the connection.

  Expects a transport module (i.e. `gen_tcp`) and a `Port`. Accepts
  authorisation params in the form of {username, password}.


  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocolV3.hello(:gen_tcp, port, 3, {}, [])
      {:ok, info}

      iex> Bolt.Sips.Internals.BoltProtocolV3.hello(:gen_tcp, port, 3, {"username", "password"}, [])
      {:ok, info}
  """
  @spec hello(atom(), port(), integer(), tuple(), Keyword.t()) ::
          {:ok, any()} | {:error, Bolt.Sips.Internals.Error.t()}
  def hello(transport, port, bolt_version, auth, options \\ [recv_timeout: 15_000]) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:hello, [auth]})

    case BoltProtocolHelper.receive_data(transport, port, bolt_version, options) do
      {:success, info} ->
        {:ok, info}

      {:failure, response} ->
        {:error, Error.exception(response, port, :hello)}

      other ->
        {:error, Error.exception(other, port, :hello)}
    end
  end

  @doc """
  Implementation of Bolt's RUN. It closes the connection.


  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocolV3.goodbye(:gen_tcp, port, 3)
      :ok

      iex> Bolt.Sips.Internals.BoltProtocolV3.goodbye(:gen_tcp, port, 3)
      :ok
  """
  def goodbye(transport, port, bolt_version) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:goodbye, []})

    try do
      Port.close(port)
      :ok
    rescue
      ArgumentError -> Error.exception("Can't close port", port, :goodbye)
    end
  end

  @doc """
  Implementation of Bolt's RUN. It passes a statement for execution on the server.

  Note that this message doesn't return the statement result. For this purpose, use PULL_ALL.
  In bolt >= 3, run has an additional paramters; metadata

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN {num} AS num", %{num: 5}, %{}, [])
      {:ok, {:success, %{"fields" => ["num"]}}}
  """
  @spec run(atom(), port(), integer(), String.t(), map(), Bolt.Sips.Metadata.t(), Keyword.t()) ::
          {:ok, any()} | {:error, Bolt.Sips.Internals.Error.t()}
  def run(transport, port, bolt_version, statement, params, metadata, options) do
    BoltProtocolHelper.send_message(
      transport,
      port,
      bolt_version,
      {:run, [statement, params, metadata]}
    )

    case BoltProtocolHelper.receive_data(transport, port, bolt_version, options) do
      {:success, _} = result ->
        {:ok, result}

      {:failure, response} ->
        {:error, Error.exception(response, port, :run)}

      %Error{} = error ->
        {:error, error}

      other ->
        {:error, Error.exception(other, port, :run)}
    end
  end

  @doc """
  Runs a statement (most likely Cypher statement) and returns a list of the
  records and a summary (Act as as a RUN + PULL_ALL).

  Records are represented using PackStream's record data type. Their Elixir
  representation is a Keyword with the indexes `:sig` and `:fields`.

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Examples

      iex> Bolt.Sips.Internals.BoltProtocol.run_statement(:gen_tcp, port, 1, "MATCH (n) RETURN n")
      [
        {:success, %{"fields" => ["n"]}},
        {:record, [sig: 1, fields: [1, "Example", "Labels", %{"some_attribute" => "some_value"}]]},
        {:success, %{"type" => "r"}}
      ]
  """
  @spec run_statement(
          atom(),
          port(),
          integer(),
          String.t(),
          map(),
          Bolt.Sips.Metadata.t(),
          Keyword.t()
        ) ::
          [
            Bolt.Sips.Internals.PackStream.Message.decoded()
          ]
          | Bolt.Sips.Internals.Error.t()
  def run_statement(transport, port, bolt_version, statement, params, metadata, options) do
    with {:ok, run_data} <-
           run(transport, port, bolt_version, statement, params, metadata, options),
         {:ok, result} <- BoltProtocol.pull_all(transport, port, bolt_version, options) do
      [run_data | result]
    else
      {:error, %Error{} = error} ->
        error

      other ->
        Error.exception(other, port, :run_statement)
    end
  end

  @doc """
  Implementation of Bolt's BEGIN. It opens a transaction.

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV3.begin(:gen_tcp, port, 3, [])
      {:ok, metadata}
  """
  @spec begin(atom(), port(), integer(), Bolt.Sips.Metadata.t() | map(), Keyword.t()) ::
          {:ok, any()} | Bolt.Sips.Internals.Error.t()
  def begin(transport, port, bolt_version, metadata, options) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:begin, [metadata]})

    case BoltProtocolHelper.receive_data(transport, port, bolt_version, options) do
      {:success, info} ->
        {:ok, info}

      {:failure, response} ->
        {:error, Error.exception(response, port, :begin)}

      other ->
        {:error, Error.exception(other, port, :begin)}
    end
  end

  @doc """
  Implementation of Bolt's COMMIT. It commits the open transaction.

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV3.commit(:gen_tcp, port, 3, [])
      :ok
  """
  @spec commit(atom(), port(), integer(), Keyword.t()) ::
          {:ok, any()} | Bolt.Sips.Internals.Error.t()
  def commit(transport, port, bolt_version, options) do
    BoltProtocolHelper.send_message(transport, port, bolt_version, {:commit, []})

    case BoltProtocolHelper.receive_data(transport, port, bolt_version, options) do
      {:success, info} ->
        {:ok, info}

      {:failure, response} ->
        {:error, Error.exception(response, port, :commit)}

      other ->
        {:error, Error.exception(other, port, :commit)}
    end
  end

  @doc """
  Implementation of Bolt's ROLLBACK. It rollbacks the open transaction.

  ## Options

  See "Shared options" in `Bolt.Sips.Internals.BoltProtocolHelper` documentation.

  ## Example

      iex> BoltProtocolV3.rollback(:gen_tcp, port, 3, [])
      :ok
  """
  @spec rollback(atom(), port(), integer(), Keyword.t()) :: :ok | Bolt.Sips.Internals.Error.t()
  def rollback(transport, port, bolt_version, options) do
    BoltProtocolHelper.treat_simple_message(:rollback, transport, port, bolt_version, options)
  end
end
