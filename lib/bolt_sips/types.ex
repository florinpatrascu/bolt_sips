defmodule Bolt.Sips.Types do
  @moduledoc """
  Basic support for representing nodes, relationships and paths belonging to
  a Neo4j graph database.

  Four supported types of entities:

  - Node
  - Relationship
  - UnboundRelationship
  - Path

  More details, about the Bolt protocol, here:
  https://github.com/boltprotocol/boltprotocol/blob/master/README.md
  """

  defmodule Entity do
    @moduledoc """
      base structure for Node and Relationship
    """
    @base_fields [id: nil, properties: nil]
    defmacro __using__(fields) do
      fields = @base_fields ++ fields

      quote do
        defstruct unquote(fields)
      end
    end
  end

  defmodule Node do
    @moduledoc """
      Self-contained graph node.

      A Node represents a node from a Neo4j graph and consists of a
      unique identifier (within the scope of its origin graph), a list of
      labels and a map of properties.

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#node
    """

    use Entity, labels: nil
  end

  defmodule Relationship do
    @moduledoc """
      Self-contained graph relationship.

      A Relationship represents a relationship from a Neo4j graph and consists of
      a unique identifier (within the scope of its origin graph), identifiers
      for the start and end nodes of that relationship, a type and a map of properties.

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#relationship
    """

    use Entity, start: nil, end: nil, type: nil
  end

  defmodule UnboundRelationship do
    @moduledoc """
      Self-contained graph relationship without endpoints.
      An UnboundRelationship represents a relationship relative to a
      separately known start point and end point.

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#unboundrelationship
    """

    use Entity, start: nil, end: nil, type: nil
  end

  defmodule Path do
    @moduledoc """
      Self-contained graph path.

      A Path is a sequence of alternating nodes and relationships corresponding to a
      walk in the graph. The path always begins and ends with a node.
      Its representation consists of a list of distinct nodes,
      a list of distinct relationships and a sequence of integers describing the
      path traversal

      https://github.com/boltprotocol/boltprotocol/blob/master/v1/_serialization.asciidoc#path
    """
    @type t :: %__MODULE__{
            nodes: List.t() | nil,
            relationships: List.t() | nil,
            sequence: List.t() | nil
          }
    defstruct nodes: nil, relationships: nil, sequence: nil

    @doc """
    represents a traversal or walk through a graph and maintains a direction
    separate from that of any relationships traversed
    """
    @spec graph(Path.t()) :: List.t() | nil
    def graph(path) do
      entities = [List.first(path.nodes)]

      draw_path(
        path.nodes,
        path.relationships,
        path.sequence,
        0,
        Enum.take_every(path.sequence, 2),
        entities,
        # last node
        List.first(path.nodes),
        # next node
        nil
      )
    end

    # @lint false
    defp draw_path(_n, _r, _s, _i, [], acc, _ln, _nn), do: acc

    defp draw_path(n, r, s, i, [h | t] = _rel_index, acc, ln, _nn) do
      next_node = Enum.at(n, Enum.at(s, 2 * i + 1))

      urel =
        if h > 0 && h < 255 do
          # rel: rels[rel_index - 1], start/end: (ln.id, next_node.id)
          rel = Enum.at(r, h - 1)

          unbound_relationship =
            [:id, :type, :properties, :start, :end]
            |> Enum.zip([rel.id, rel.type, rel.properties, ln.id, next_node.id])

          struct(UnboundRelationship, unbound_relationship)
        else
          # rel: rels[-rel_index - 1], start/end: (next_node.id, ln.id)
          # Neo4j sends: -1, and Boltex returns 255 instead? Investigating,
          # meanwhile ugly path:
          # oh dear ...
          haha = if h == 255, do: -1, else: h
          rel = Enum.at(r, -haha - 1)

          unbound_relationship =
            [:id, :type, :properties, :start, :end]
            |> Enum.zip([rel.id, rel.type, rel.properties, next_node.id, ln.id])

          struct(UnboundRelationship, unbound_relationship)
        end

      draw_path(n, r, s, i + 1, t, (acc ++ [urel]) ++ [next_node], next_node, ln)
    end
  end
end
