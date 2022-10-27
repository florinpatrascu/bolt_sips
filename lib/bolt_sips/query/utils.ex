defmodule Bolt.Sips.Query.Utils do
  @moduledoc """
  Util functions to be used together with `Bolt.Sips.Query`.
  """

  @doc """
  `prepared_statement/2` should be used when parameters are not possible to use, for example
  in this situation: https://neo4j.com/developer/kb/protecting-against-cypher-injection/#_when_you_must_append_into_a_query_string_sanitize_your_inputs

  If we want to have label or relationship names being passed as variables, we can't use Neo4j parameters, so we'd be susceptible to label injection.
  This function escapes `'` characters from the values passed and replaces them in the query string.

  The code bellow would return a safe query string that we can use with `Bolt.Sips.Query` later.

  iex>"CREATE (s:{{label}}) SET s.name = 'Some Name'"
  ...>  |> Bolt.Sips.Query.Utils.prepared_statement([label: "Something' Bad"])
  ```
  """
  @spec prepared_statement(String.t(), keyword({atom(), String.t()})) :: String.t()
  def prepared_statement(query_string, variables \\ []) when is_list(variables) do
    prepared_vars =
      Enum.map(variables, fn {key, value} ->
        case value do
          nil -> {key, ""}
          _ -> {key, String.replace(value, "'", "\\'")}
        end
      end)

    Enum.reduce(prepared_vars, query_string, fn {key, var}, acc ->
      String.replace(acc, "{{#{key}}}", var)
    end)
  end
end
