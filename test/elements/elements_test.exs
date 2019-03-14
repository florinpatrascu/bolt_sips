defmodule Bolt.Sips.Elements.Test do
  use ExUnit.Case, async: true
  doctest Bolt.Sips

  alias Bolt.Sips.{Success, Error, Response}
  alias Bolt.Sips.Types.{Node, Relationship, Path}

  # MATCH
  #   (p:Person {name: "Keanu Reeves"})-[r:ACTED_IN]->(m:Movie)
  # WHERE
  #   m.title IN ["Johnny Mnemonic", "Something's Gotta Give"]
  # RETURN
  # p, r
  @success [
    success: %{"fields" => ["p", "r"]},
    record: [
      %Bolt.Sips.Types.Node{
        id: 1,
        labels: ["Person"],
        properties: %{"born" => 1964, "name" => "Keanu Reeves"}
      },
      %Bolt.Sips.Types.Relationship{
        end: 154,
        id: 221,
        properties: %{"roles" => ["Julian Mercer"]},
        start: 1,
        type: "ACTED_IN"
      }
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 1,
        labels: ["Person"],
        properties: %{"born" => 1964, "name" => "Keanu Reeves"}
      },
      %Bolt.Sips.Types.Relationship{
        end: 107,
        id: 139,
        properties: %{"roles" => ["Johnny Mnemonic"]},
        start: 401,
        type: "ACTED_IN"
      }
    ],
    success: %{"type" => "r"}
  ]

  @failure {
    :failure,
    %{
      "code" => "Neo.ClientError.Statement.SyntaxError",
      "message" => "Invalid input 'r': expected whitespace..."
    }
  }

  # "CREATE (person:Person {name: 'Arthur'})"
  @success_with_stats [
    success: %{"fields" => []},
    success: %{
      "stats" => %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1},
      "type" => "w"
    }
  ]

  # "EXPLAIN MATCH (n), (m) RETURN n, m"
  @explain [
    success: %{"fields" => []},
    success: %{
      "notifications" => [
        %{
          "code" => "Neo.ClientNotification.Statement.CartesianProductWarning",
          "description" =>
            "If a part of a query contains multiple disconnected patterns, this will build a cartesian product between all those parts. This may produce a large amount of data and slow down query processing. While occasionally intended, it may often be possible to reformulate the query that avoids the use of this cross product, perhaps by adding a relationship between the different parts or by using OPTIONAL MATCH (identifier is: (m))",
          "position" => %{"column" => 1, "line" => 1, "offset" => 0},
          "severity" => "WARNING",
          "title" => "This query builds a cartesian product between disconnected patterns."
        }
      ],
      "plan" => %{
        "args" => %{
          "EstimatedRows" => 3.24e4,
          "KeyNames" => "n, m",
          "planner" => "COST",
          "planner-impl" => "IDP",
          "runtime" => "INTERPRETED",
          "runtime-impl" => "INTERPRETED",
          "version" => "CYPHER 3.0"
        },
        "children" => [
          %{
            "args" => %{"EstimatedRows" => 3.24e4},
            "children" => [
              %{
                "args" => %{"EstimatedRows" => 180.0},
                "children" => [],
                "identifiers" => ["n"],
                "operatorType" => "AllNodesScan"
              },
              %{
                "args" => %{"EstimatedRows" => 180.0},
                "children" => [],
                "identifiers" => ["m"],
                "operatorType" => "AllNodesScan"
              }
            ],
            "identifiers" => ["m", "n"],
            "operatorType" => "CartesianProduct"
          }
        ],
        "identifiers" => ["m", "n"],
        "operatorType" => "ProduceResults"
      },
      "type" => "r"
    }
  ]

  # "PROFILE CREATE (n) RETURN n"
  @profile [
    success: %{"fields" => ["n"]},
    record: [[sig: 78, fields: [193, [], %{}]]],
    success: %{
      "profile" => %{
        "args" => %{
          "DbHits" => 0,
          "EstimatedRows" => 1.0,
          "KeyNames" => "n",
          "Rows" => 1,
          "planner" => "COST",
          "planner-impl" => "IDP",
          "runtime" => "INTERPRETED",
          "runtime-impl" => "INTERPRETED",
          "version" => "CYPHER 3.0"
        },
        "children" => [
          %{
            "args" => %{"DbHits" => 2, "EstimatedRows" => 1.0, "Rows" => 1},
            "children" => [],
            "dbHits" => 2,
            "identifiers" => ["n"],
            "operatorType" => "CreateNode",
            "rows" => 1
          }
        ],
        "dbHits" => 0,
        "identifiers" => ["n"],
        "operatorType" => "ProduceResults",
        "rows" => 1
      },
      "stats" => %{"nodes-created" => 1},
      "type" => "rw"
    }
  ]

  # MERGE p=({name:'Alice'})-[:KNOWS]->({name:'Bob'}) RETURN p
  @path [
    success: %{"fields" => ["p"], "result_available_after" => 17},
    record: [
      %Bolt.Sips.Types.Path{
        nodes: [
          %Bolt.Sips.Types.Node{id: 172, labels: [], properties: %{"name" => "Alice"}},
          %Bolt.Sips.Types.Node{id: 182, labels: [], properties: %{"name" => "Bob"}}
        ],
        relationships: [
          %Bolt.Sips.Types.UnboundRelationship{
            end: nil,
            id: 259,
            properties: %{},
            start: nil,
            type: "KNOWS"
          }
        ],
        sequence: [1, 1]
      }
    ],
    success: %{
      "stats" => %{"nodes-created" => 2, "properties-set" => 2, "relationships-created" => 1},
      "type" => "rw"
    }
  ]

  # "MATCH (p:Person {bolt_sips: true})  RETURN p, p.name AS name,
  #  upper(p.name) as NAME, coalesce(p.nickname,\"n/a\") AS nickname,
  #  {name: p.name, label:head(labels(p))} AS person"
  @coalesce [
    success: %{
      "fields" => ["p", "name", "NAME", "nickname", "person"],
      "result_available_after" => 13
    },
    record: [
      %Bolt.Sips.Types.Node{
        id: 432,
        labels: ["Person"],
        properties: %{"bolt_sips" => true, "name" => "Patrick Rothfuss"}
      },
      "Patrick Rothfuss",
      "PATRICK ROTHFUSS",
      "n/a",
      %{"label" => "Person", "name" => "Patrick Rothfuss"}
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 176,
        labels: ["Person"],
        properties: %{"bolt_sips" => true, "name" => "Kote"}
      },
      "Kote",
      "KOTE",
      "n/a",
      %{"label" => "Person", "name" => "Kote"}
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 351,
        labels: ["Person"],
        properties: %{"bolt_sips" => true, "name" => "Denna"}
      },
      "Denna",
      "DENNA",
      "n/a",
      %{"label" => "Person", "name" => "Denna"}
    ],
    success: %{"result_consumed_after" => 1, "type" => "r"}
  ]

  # match (a)-[:HAS*]->(b) return collect(distinct b)
  @collect_distinct [
    success: %{"fields" => ["collect(distinct b)"]},
    record: [
      [
        %Bolt.Sips.Types.Node{
          id: 76,
          labels: ["Wheel"],
          properties: %{"bolt_sips" => true, "spokes" => 3}
        },
        %Bolt.Sips.Types.Node{
          id: 77,
          labels: ["Wheel"],
          properties: %{"bolt_sips" => true, "spokes" => 32}
        }
      ]
    ],
    success: %{"type" => "r"}
  ]

  @complex_path [
    success: %{"fields" => ["db", "expert", "path"]},
    record: [
      [sig: 78, fields: [114, ["Database"], %{"name" => "Neo4j"}]],
      [sig: 78, fields: [119, ["Person", "Expert"], %{"name" => "Amanda"}]],
      [
        sig: 80,
        fields: [
          [
            [sig: 78, fields: [107, ["Person"], %{"name" => "You"}]],
            [sig: 78, fields: [108, ["Person"], %{"name" => "Anna"}]],
            [sig: 78, fields: [119, ["Person", "Expert"], %{"name" => "Amanda"}]]
          ],
          [[sig: 114, fields: [282, "FRIEND", %{}]], [sig: 114, fields: [289, "FRIEND", %{}]]],
          [1, 1, 2, 2]
        ]
      ]
    ],
    record: [
      [sig: 78, fields: [114, ["Database"], %{"name" => "Neo4j"}]],
      [sig: 78, fields: [116, ["Person", "Expert"], %{"name" => "Amanda"}]],
      [
        sig: 80,
        fields: [
          [
            [sig: 78, fields: [107, ["Person"], %{"name" => "You"}]],
            [sig: 78, fields: [108, ["Person"], %{"name" => "Anna"}]],
            [sig: 78, fields: [116, ["Person", "Expert"], %{"name" => "Amanda"}]]
          ],
          [[sig: 114, fields: [282, "FRIEND", %{}]], [sig: 114, fields: [287, "FRIEND", %{}]]],
          [1, 1, 2, 2]
        ]
      ]
    ],
    record: [
      [sig: 78, fields: [114, ["Database"], %{"name" => "Neo4j"}]],
      [sig: 78, fields: [115, ["Person", "Expert"], %{"name" => "Amanda"}]],
      [
        sig: 80,
        fields: [
          [
            [sig: 78, fields: [107, ["Person"], %{"name" => "You"}]],
            [sig: 78, fields: [108, ["Person"], %{"name" => "Anna"}]],
            [sig: 78, fields: [115, ["Person", "Expert"], %{"name" => "Amanda"}]]
          ],
          [[sig: 114, fields: [282, "FRIEND", %{}]], [sig: 114, fields: [285, "FRIEND", %{}]]],
          [1, 1, 2, 2]
        ]
      ]
    ],
    success: %{"type" => "r"}
  ]

  # MATCH (m:Movie)<-[:ACTED_IN]-(a:Person)
  # RETURN m.title as movie, collect(a.name) as cast LIMIT 5
  @movie_crew [
    success: %{"fields" => ["movie", "cast"]},
    record: ["Apollo 13", ["Tom Hanks", "Kevin Bacon", "Ed Harris", "Bill Paxton", "Gary Sinise"]],
    success: %{"type" => "r"}
  ]

  @doc """
  MATCH (you {name:"You"})
  MATCH (expert)-[:WORKED_WITH]->(db:Database {name: "Neo4j"})
  MATCH path = shortestPath( (you)-[:FRIEND*..5]-(expert) )
  RETURN db,expert,path

  $ python2 -m neo4j 'MATCH (you {name:"You"}) MATCH (expert)-[:WORKED_WITH]->(db:Database {name: "Neo4j"}) MATCH path = shortestPath( (you)-[:FRIEND*..5]-(expert) ) RETURN db,expert,path'
  <Node id=130 labels=set([u'Database']) properties={u'name': u'Neo4j'}>
  <Node id=129 labels=set([u'Person', u'Expert']) properties={u'name': u'Amanda'}>
  <Path start=126 end=129 size=2>

  """
  @complex_path [
    success: %{"fields" => ["db", "expert", "path"]},
    record: [
      %Bolt.Sips.Types.Node{id: 130, labels: ["Database"], properties: %{"name" => "Neo4j"}},
      %Bolt.Sips.Types.Node{
        id: 129,
        labels: ["Person", "Expert"],
        properties: %{"name" => "Amanda"}
      },
      %Bolt.Sips.Types.Path{
        nodes: [
          %Bolt.Sips.Types.Node{id: 126, labels: ["Person"], properties: %{"name" => "You"}},
          %Bolt.Sips.Types.Node{id: 125, labels: ["Person"], properties: %{"name" => "Anna"}},
          %Bolt.Sips.Types.Node{
            id: 129,
            labels: ["Person", "Expert"],
            properties: %{"name" => "Amanda"}
          }
        ],
        relationships: [
          %Bolt.Sips.Types.UnboundRelationship{
            end: nil,
            id: 294,
            properties: %{},
            start: nil,
            type: "FRIEND"
          },
          %Bolt.Sips.Types.UnboundRelationship{
            end: nil,
            id: 302,
            properties: %{},
            start: nil,
            type: "FRIEND"
          }
        ],
        sequence: [1, 1, 2, 2]
      }
    ],
    success: %{"type" => "r"}
  ]

  # Issue #55 : https://github.com/florinpatrascu/bolt_sips/issues/55
  # Specific types in properties should be successfully decoded
  @types_in_properties [
    success: %{"fields" => ["t1", "t2", "rel"]},
    record: [
      %Bolt.Sips.Types.Node{
        id: 69,
        labels: ["Test"],
        properties: %{
          "created" => %Bolt.Sips.Types.DateTimeWithTZOffset{
            naive_datetime: ~N[2016-05-24 13:26:08.543],
            timezone_offset: 7200
          },
          "uuid" => 12345
        }
      },
      %Bolt.Sips.Types.Node{id: 30, labels: ["Test"], properties: %{"uuid" => 6789}},
      %Bolt.Sips.Types.Relationship{
        end: 30,
        id: 5,
        properties: %{
          "created" => %Bolt.Sips.Types.DateTimeWithTZOffset{
            naive_datetime: ~N[2016-05-24 13:26:08.543],
            timezone_offset: 7200
          }
        },
        start: 69,
        type: "UPDATED_TO_"
      }
    ],
    success: %{"type" => "r"}
  ]

  test "records from a complex Path" do
    row = Response.transform(@complex_path) |> List.first()
    graph = Path.graph(row["path"])
    # assert the starting and the ending of the Path
    assert [126, 129] == [List.first(graph).id, List.last(graph).id]
  end

  test "Movie and Crew" do
    assert %{"cast" => cast, "movie" => movie} = Response.transform(@movie_crew) |> List.first()
    assert movie == "Apollo 13"
    assert cast == ["Tom Hanks", "Kevin Bacon", "Ed Harris", "Bill Paxton", "Gary Sinise"]
  end

  test "match (a)-[:HAS*]->(b) return collect(distinct b)" do
    row = Response.transform(@collect_distinct) |> List.first()
    assert length(row["collect(distinct b)"]) == 2

    assert row["collect(distinct b)"] == [
             %Bolt.Sips.Types.Node{
               id: 76,
               labels: ["Wheel"],
               properties: %{"bolt_sips" => true, "spokes" => 3}
             },
             %Bolt.Sips.Types.Node{
               id: 77,
               labels: ["Wheel"],
               properties: %{"bolt_sips" => true, "spokes" => 32}
             }
           ]
  end

  test "MATCH with coalesce" do
    rows = Response.transform(@coalesce)
    assert length(rows) == 3
    row = List.first(rows)

    assert row["p"] == %Bolt.Sips.Types.Node{
             id: 432,
             labels: ["Person"],
             properties: %{"name" => "Patrick Rothfuss", "bolt_sips" => true}
           }

    assert row["name"] == "Patrick Rothfuss"
    assert row["NAME"] == "PATRICK ROTHFUSS"
    assert row["nickname"] == "n/a"
    assert row["person"] == %{"label" => "Person", "name" => "Patrick Rothfuss"}
  end

  test "records from a Path" do
    assert [%{"p" => path}] = Response.transform(@path)

    assert path ==
             %Bolt.Sips.Types.Path{
               nodes: [
                 %Bolt.Sips.Types.Node{id: 172, labels: [], properties: %{"name" => "Alice"}},
                 %Bolt.Sips.Types.Node{id: 182, labels: [], properties: %{"name" => "Bob"}}
               ],
               relationships: [
                 %Bolt.Sips.Types.UnboundRelationship{id: 259, properties: %{}, type: "KNOWS"}
               ],
               sequence: [1, 1]
             }
  end

  test "success on PROFILE CREATE (n) RETURN n" do
    # this works too: r = Response.transform(@profile)
    {:ok, s} = Success.new(@profile)
    assert s.fields == ["n"]
    assert s.records == [[[sig: 78, fields: [193, [], %{}]]]]
    assert s.type == "rw"
    refute s.profile == nil
  end

  test "success on EXPLAIN MATCH" do
    {:ok, s} = Success.new(@explain)
    assert s.fields == []
    assert s.type == "r"

    assert s.plan["args"] == %{
             "EstimatedRows" => 3.24e4,
             "KeyNames" => "n, m",
             "planner" => "COST",
             "planner-impl" => "IDP",
             "runtime" => "INTERPRETED",
             "runtime-impl" => "INTERPRETED",
             "version" => "CYPHER 3.0"
           }
  end

  test "success" do
    {:ok, s} = Success.new(@success)

    assert %Bolt.Sips.Success{
             fields: ["p", "r"],
             notifications: nil,
             plan: nil,
             profile: nil,
             records: [
               [
                 %Bolt.Sips.Types.Node{
                   id: 1,
                   labels: ["Person"],
                   properties: %{"born" => 1964, "name" => "Keanu Reeves"}
                 },
                 %Bolt.Sips.Types.Relationship{
                   end: 154,
                   id: 221,
                   properties: %{"roles" => ["Julian Mercer"]},
                   start: 1,
                   type: "ACTED_IN"
                 }
               ],
               [
                 %Bolt.Sips.Types.Node{
                   id: 1,
                   labels: ["Person"],
                   properties: %{"born" => 1964, "name" => "Keanu Reeves"}
                 },
                 %Bolt.Sips.Types.Relationship{
                   end: 107,
                   id: 139,
                   properties: %{"roles" => ["Johnny Mnemonic"]},
                   start: 401,
                   type: "ACTED_IN"
                 }
               ]
             ],
             stats: nil,
             type: "r"
           } == s

    assert ["p", "r"] == s.fields
    assert "r" == s.type
    assert length(s.records) == 2

    assert [:__struct__, :fields, :notifications, :plan, :profile, :records, :stats, :type] ==
             Map.keys(s)
  end

  test "success with stats" do
    {:ok, s} = Success.new(@success_with_stats)
    assert s.stats == %{"labels-added" => 1, "nodes-created" => 1, "properties-set" => 1}
    assert s.type == "w"
    assert s.fields == []
  end

  test "failure" do
    {:error, f} = Error.new(@failure)
    assert f.code == "Neo.ClientError.Statement.SyntaxError"
    assert f.message == "Invalid input 'r': expected whitespace..."
  end

  test "success and receive failure" do
    {:error, f} = Success.new(@failure)
    assert f.code == "Neo.ClientError.Statement.SyntaxError"
    assert f.message == "Invalid input 'r': expected whitespace..."
  end

  test "a record extraction" do
    record = Response.transform(@success) |> List.first()

    assert record["p"] == %Node{
             id: 1,
             labels: ["Person"],
             properties: %{"born" => 1964, "name" => "Keanu Reeves"}
           }

    assert record["r"] == %Relationship{
             id: 221,
             start: 1,
             end: 154,
             properties: %{"roles" => ["Julian Mercer"]},
             type: "ACTED_IN"
           }
  end

  test "success with specific types in properties" do
    expected = [
      %{
        "rel" => %Bolt.Sips.Types.Relationship{
          end: 30,
          id: 5,
          start: 69,
          type: "UPDATED_TO_",
          properties: %{
            "created" => %Bolt.Sips.Types.DateTimeWithTZOffset{
              naive_datetime: ~N[2016-05-24 13:26:08.543],
              timezone_offset: 7200
            }
          }
        },
        "t1" => %Bolt.Sips.Types.Node{
          id: 69,
          labels: ["Test"],
          properties: %{
            "created" => %Bolt.Sips.Types.DateTimeWithTZOffset{
              naive_datetime: ~N[2016-05-24 13:26:08.543],
              timezone_offset: 7200
            },
            "uuid" => 12345
          }
        },
        "t2" => %Bolt.Sips.Types.Node{id: 30, labels: ["Test"], properties: %{"uuid" => 6789}}
      }
    ]

    assert expected == Response.transform(@types_in_properties)
  end
end
