defmodule Bolt.Sips.Utils do
  @moduledoc false
  # Common utilities

  @default_hostname "localhost"
  @default_bolt_port 7687

  @default_driver_options [
    hostname: @default_hostname,
    port: @default_bolt_port,
    pool_size: 15,
    max_overflow: 0,
    timeout: 15_000,
    ssl: false,
    socket: Bolt.Sips.Socket,
    with_etls: false,
    retry_linear_backoff: [delay: 150, factor: 2, tries: 3],
    schema: "bolt",
    prefix: :default
  ]

  @doc """
  Generate a random string.
  """
  def random_id, do: :rand.uniform() |> Float.to_string() |> String.slice(2..10)

  @doc """
  Fills in the given `opts` with default options.
  """
  @spec default_config(Keyword.t()) :: Keyword.t()
  def default_config(), do: Application.get_env(:bolt_sips, Bolt) |> default_config

  def default_config(opts) do
    config =
      @default_driver_options
      |> Keyword.merge(opts)

    ssl_or_sock = if(Keyword.get(config, :ssl), do: :ssl, else: Keyword.get(config, :socket))

    config
    |> Keyword.put_new(:hostname, System.get_env("NEO4J_HOST") || @default_hostname)
    |> Keyword.put_new(:port, System.get_env("NEO4J_PORT") || @default_bolt_port)
    |> Keyword.put_new(:pool_size, 5)
    |> Keyword.put_new(:max_overflow, 2)
    |> Keyword.put_new(:timeout, 15_000)
    |> Keyword.put_new(:ssl, false)
    |> Keyword.put_new(:socket, Bolt.Sips.Socket)
    |> Keyword.put_new(:with_etls, false)
    |> Keyword.put_new(:retry_linear_backoff, delay: 150, factor: 2, tries: 3)
    |> Keyword.put_new(:schema, "bolt")
    |> Keyword.put_new(:path, "")
    |> Keyword.put_new(:prefix, :default)
    |> or_use_url_if_present
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Keyword.put(:socket, ssl_or_sock)
  end

  @doc """
  source: https://github.com/eksperimental/experimental_elixir/blob/master/lib/kernel_modulo.ex
  Modulo operation.

  Returns the remainder after division of `number` by `modulus`.
  The sign of the result will always be the same sign as the `modulus`.

  More information: [Modulo operation](https://en.wikipedia.org/wiki/Modulo_operation) on Wikipedia.
  ## Examples
    iex> mod(17, 17)
    0
    iex> mod(17, 1)
    0
    iex> mod(17, 13)
    4
    iex> mod(-17, 13)
    9
    iex> mod(17, -13)
    -9
    iex> mod(-17, -13)
    -4
    iex> mod(17, 26)
    17
    iex> mod(-17, 26)
    9
    iex> mod(17, -26)
    -9
    iex> mod(-17, -26)
    -17
    iex> mod(17, 0)
    ** (ArithmeticError) bad argument in arithmetic expression
    iex> mod(1.5, 2)
    ** (FunctionClauseError) no function clause matching in Experimental.KernelModulo.mod/2
  """
  @spec mod(integer, integer) :: non_neg_integer
  def mod(number, modulus) when is_integer(number) and is_integer(modulus) do
    remainder = rem(number, modulus)

    if (remainder > 0 and modulus < 0) or (remainder < 0 and modulus > 0) do
      remainder + modulus
    else
      remainder
    end
  end

  @doc false
  defp or_use_url_if_present(config) do
    if Keyword.has_key?(config, :url) do
      f =
        config[:url]
        |> to_string()
        |> URI.parse()

      schema = if f.scheme, do: f.scheme, else: "bolt"

      config
      |> Keyword.put(:hostname, f.host)
      |> Keyword.put(:schema, schema)
      |> Keyword.put(:query, f.query)
      |> Keyword.put(:path, f.path)
      |> Keyword.put(:fragment, f.fragment)
      |> Keyword.put(:routing_context, routing_context(f.query))
      |> Keyword.put(:port, port_from_url(f.port))
      |> username_and_password(f.userinfo)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    else
      config
    end
  end

  @username_password ~r"""
  ^
  (?: (?<username> \* | [a-zA-Z0-9%_.!~*'();&=+$,-]+)
    (?: : (?<password> \* | [a-zA-Z0-9%_.!~*'();&=+$,-]*))?
  )?
  $
  """x
  @spec username_and_password(Keyword.t(), String.t()) :: Keyword.t()
  defp username_and_password(config, uri_user_info) when is_binary(uri_user_info) do
    case Regex.named_captures(@username_password, uri_user_info) do
      %{"username" => username, "password" => password} ->
        config
        |> Keyword.put(:basic_auth, username: username, password: password)

      _ ->
        config
    end
  end

  defp username_and_password(config, _), do: config

  @spec port_from_url(integer) :: integer
  defp port_from_url(port)
       when is_nil(port)
       when not is_integer(port),
       do: @default_bolt_port

  defp port_from_url(port) when is_integer(port), do: port

  defp port_from_url(_port), do: @default_bolt_port

  @accepted_units_of_time [:seconds, :millisecond, :microsecond, :nanosecond]
  @accepted_units_of_time_str Enum.join(@accepted_units_of_time, ", ")

  @doc """
  return now for UTC, in :seconds, :millisecond, :microsecond and :nanosecond
  """
  @spec now(unit :: :seconds | :millisecond | :microsecond | :nanosecond) :: integer
  def now(unit \\ :seconds)
  def now(unit) when unit in @accepted_units_of_time, do: :os.system_time(unit)

  def now(unit),
    do:
      raise(
        ArgumentError,
        "expected one of these: #{@accepted_units_of_time_str}, but received: #{inspect(unit)}, instead."
      )

  defp routing_context(nil), do: decode("")
  defp routing_context(query), do: decode(query)

  def decode(query) do
    do_decode(:binary.split(query, [";", ",", "&"], [:global]), %{})
  end

  defp do_decode([], acc), do: acc

  defp do_decode([h | t], acc) do
    case decode_kv(h) do
      {k, v} -> do_decode(t, Map.put(acc, k, v))
      false -> do_decode(t, acc)
    end
  end

  # borrowed some code from Plug
  defp decode_kv(""), do: false
  defp decode_kv(<<?$, _::binary>>), do: false
  defp decode_kv(<<h, t::binary>>) when h in [?\s, ?\t], do: decode_kv(t)
  defp decode_kv(kv), do: decode_key(kv, "")

  defp decode_key("", _key), do: false
  defp decode_key(<<?=, _::binary>>, ""), do: false
  defp decode_key(<<?=, t::binary>>, key), do: decode_value(t, "", key, "")
  defp decode_key(<<h, _::binary>>, _key) when h in [?\s, ?\t, ?\r, ?\n, ?\v, ?\f], do: false
  defp decode_key(<<h, t::binary>>, key), do: decode_key(t, <<key::binary, h>>)

  defp decode_value("", _spaces, key, value), do: {key, value}

  defp decode_value(<<?\s, t::binary>>, spaces, key, value),
    do: decode_value(t, <<spaces::binary, ?\s>>, key, value)

  defp decode_value(<<h, _::binary>>, _spaces, _key, _value) when h in [?\t, ?\r, ?\n, ?\v, ?\f],
    do: false

  defp decode_value(<<h, t::binary>>, spaces, key, value),
    do: decode_value(t, "", key, <<value::binary, spaces::binary, h>>)
end
