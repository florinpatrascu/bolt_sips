defmodule Bolt.Sips.Success do
  @moduledoc """
  Bolt returns success or Error, in response to our requests.
  """

  alias __MODULE__
  alias Bolt.Sips.Error

  defstruct [
    fields: nil, type: nil, records: nil, stats: nil,
    notifications: nil, plan: nil, profile: nil
  ]

  @doc """
  parses a record received from Bolt and returns `{:ok, %Bolt.Sips.Success{}}`
  or `{:error, %Bolt.Sips.Error{}}` if it can't find the success key.

  """
  def new(r) do
    case Error.new(r) do
      {:error, error} -> {:error, error}
      _ ->
        case Keyword.has_key?(r, :success) && Keyword.get_values(r, :success) do
          [f|t] ->
            %{"fields" => fields} = f
            case List.first(t) do
              %{"profile" => profile, "stats" => stats, "type" => type} ->
                {:ok, %Success{fields: fields, type: type, profile: profile,
                         stats: stats, records: Keyword.get_values(r, :record)}}

              %{"notifications" => notifications, "plan" => plan, "type" => type} ->
                {:ok, %Success{fields: fields, type: type,
                         notifications: notifications, plan: plan}}

              %{"plan" => plan, "type" => type} ->
                {:ok, %Success{fields: fields, type: type, plan: plan,
                         notifications: []}}

              %{"stats" => stats, "type" => type} ->
                {:ok, %Success{fields: fields, type: type, stats: stats,
                         records: Keyword.get_values(r, :record)}}

              %{"type" => type} ->
                {:ok, %Success{fields: fields, type: type,
                         records: Keyword.get_values(r, :record)}}
            end
          _ -> r
        end
    end
  end

end
