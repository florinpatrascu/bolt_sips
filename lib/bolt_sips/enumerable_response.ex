defimpl Enumerable, for: Bolt.Sips.Response do
  alias Bolt.Sips.Response

  def count(%Response{results: nil}), do: {:ok, 0}
  def count(%Response{results: []}), do: {:ok, 0}
  def count(%Response{results: results}), do: {:ok, length(results)}

  def member?(%Response{fields: fields}, field), do: {:ok, Enum.member?(fields, field)}
  def slice(_response), do: {:error, __MODULE__}

  def reduce(%Response{results: []}, acc, _fun), do: acc

  def reduce(%Response{results: results}, acc, fun) when is_list(results),
    do: reduce_list(results, acc, fun)

  defp reduce_list(_, {:halt, acc}, _fun), do: {:halted, acc}
  defp reduce_list(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce_list(list, &1, fun)}
  defp reduce_list([], {:cont, acc}, _fun), do: {:done, acc}
  defp reduce_list([h | t], {:cont, acc}, fun), do: reduce_list(t, fun.(h, acc), fun)

  @doc false
  def slice(%Response{results: []}, _start, _count), do: []
  def slice(_response, _start, 0), do: []
  def slice(%Response{results: [head | tail]}, 0, count), do: [head | slice(tail, 0, count - 1)]
  def slice(%Response{results: [_head | tail]}, start, count), do: slice(tail, start - 1, count)
end
