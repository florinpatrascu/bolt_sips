defmodule Bolt.Sips.Utils do
  @moduledoc "Common utilities"

  @doc """
  Generate a random string.
  """
  def random_id, do: :rand.uniform |> Float.to_string |> String.slice(2..10)

  @doc """
  Fills in the given `opts` with default options.
  """
  @spec default_config(Keyword.t) :: Keyword.t
  def default_config(config \\ Application.get_env(:bolt_sips, Bolt)) do
    config
    |> Keyword.put_new(:hostname, System.get_env("NEO4J_HOST") || "localhost")
    |> Keyword.put_new(:port, System.get_env("NEO4J_PORT") || 7687)
    |> Keyword.put_new(:pool_size, 5)
    |> Keyword.put_new(:max_overflow, 2)
    |> Keyword.put_new(:timeout, 15_000)
    |> Keyword.put_new(:secure, false)
    |> Keyword.put_new(:socket, :gen_tcp)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)

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
      case rem(number, modulus) do
        remainder when remainder > 0 and modulus < 0 or remainder < 0 and modulus > 0 ->
          remainder + modulus
        remainder ->
          remainder
      end
    end

end
