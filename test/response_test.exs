defmodule ResponseTest do
  use ExUnit.Case

  alias Bolt.Sips.Response
  # import ExUnit.CaptureLog

  @explain [
    success: %{"fields" => ["n"], "t_first" => 1},
    success: %{
      "bookmark" => "neo4j:bookmark:v1:tx13440",
      "plan" => %{
        "args" => %{
          "EstimatedRows" => 1.0,
          "planner" => "COST",
          "planner-impl" => "IDP",
          "planner-version" => "3.5",
          "runtime" => "INTERPRETED",
          "runtime-impl" => "INTERPRETED",
          "runtime-version" => "3.5",
          "version" => "CYPHER 3.5"
        },
        "children" => [
          %{
            "args" => %{"EstimatedRows" => 1.0},
            "children" => [],
            "identifiers" => ["n"],
            "operatorType" => "Create"
          }
        ],
        "identifiers" => ["n"],
        "operatorType" => "ProduceResults"
      },
      "t_last" => 0,
      "type" => "rw"
    }
  ]

  @notifications [
    success: %{"fields" => ["n", "m"], "t_first" => 0},
    success: %{
      "bookmark" => "neo4j:bookmark:v1:tx13440",
      "notifications" => [
        %{
          "code" => "Neo.ClientNotification.Statement.CartesianProductWarning",
          "description" => "bad juju",
          "position" => %{"column" => 9, "line" => 1, "offset" => 8},
          "severity" => "WARNING",
          "title" => "This query builds a cartesian product between disconnected patterns."
        }
      ],
      "plan" => %{
        "args" => %{
          "EstimatedRows" => 36.0,
          "planner" => "COST",
          "planner-impl" => "IDP",
          "planner-version" => "3.5",
          "runtime" => "INTERPRETED",
          "runtime-impl" => "INTERPRETED",
          "runtime-version" => "3.5",
          "version" => "CYPHER 3.5"
        },
        "children" => [
          %{
            "args" => %{"EstimatedRows" => 36.0},
            "children" => [
              %{
                "args" => %{"EstimatedRows" => 6.0},
                "children" => [],
                "identifiers" => ["n"],
                "operatorType" => "AllNodesScan"
              },
              %{
                "args" => %{"EstimatedRows" => 6.0},
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
      "t_last" => 0,
      "type" => "r"
    }
  ]

  @profile_no_results [
    success: %{"fields" => [], "t_first" => 20},
    success: %{
      "bookmark" => "neo4j:bookmark:v1:tx48642",
      "profile" => %{
        "args" => %{
          "DbHits" => 0,
          "EstimatedRows" => 1.0,
          "PageCacheHitRatio" => 0.0,
          "PageCacheHits" => 0,
          "PageCacheMisses" => 0,
          "Rows" => 0,
          "planner" => "COST",
          "planner-impl" => "IDP",
          "planner-version" => "3.5",
          "runtime" => "SLOTTED",
          "runtime-impl" => "SLOTTED",
          "runtime-version" => "3.5",
          "version" => "CYPHER 3.5"
        },
        "children" => [
          %{
            "args" => %{
              "DbHits" => 0,
              "EstimatedRows" => 1.0,
              "PageCacheHitRatio" => 0.0,
              "PageCacheHits" => 0,
              "PageCacheMisses" => 0,
              "Rows" => 0
            },
            "children" => [
              %{
                "args" => %{
                  "DbHits" => 3,
                  "EstimatedRows" => 1.0,
                  "PageCacheHitRatio" => 0.0,
                  "PageCacheHits" => 0,
                  "PageCacheMisses" => 0,
                  "Rows" => 1
                },
                "children" => [],
                "dbHits" => 3,
                "identifiers" => ["n"],
                "operatorType" => "Create",
                "pageCacheHitRatio" => 0.0,
                "pageCacheHits" => 0,
                "pageCacheMisses" => 0,
                "rows" => 1
              }
            ],
            "dbHits" => 0,
            "identifiers" => ["n"],
            "operatorType" => "EmptyResult",
            "pageCacheHitRatio" => 0.0,
            "pageCacheHits" => 0,
            "pageCacheMisses" => 0,
            "rows" => 0
          }
        ],
        "dbHits" => 0,
        "identifiers" => ["n"],
        "operatorType" => "ProduceResults",
        "pageCacheHitRatio" => 0.0,
        "pageCacheHits" => 0,
        "pageCacheMisses" => 0,
        "rows" => 0
      },
      "stats" => %{
        "labels-added" => 1,
        "nodes-created" => 1,
        "properties-set" => 1
      },
      "t_last" => 0,
      "type" => "w"
    }
  ]

  @profile_results [
    success: %{"fields" => ["num"], "t_first" => 1},
    record: [1],
    success: %{
      "bookmark" => "neo4j:bookmark:v1:tx48642",
      "profile" => %{
        "args" => %{
          "DbHits" => 0,
          "EstimatedRows" => 1.0,
          "PageCacheHitRatio" => 0.0,
          "PageCacheHits" => 0,
          "PageCacheMisses" => 0,
          "Rows" => 1,
          "Time" => 25980,
          "planner" => "COST",
          "planner-impl" => "IDP",
          "planner-version" => "3.5",
          "runtime" => "COMPILED",
          "runtime-impl" => "COMPILED",
          "runtime-version" => "3.5",
          "version" => "CYPHER 3.5"
        },
        "children" => [
          %{
            "args" => %{
              "DbHits" => 0,
              "EstimatedRows" => 1.0,
              "Expressions" => "{num : $`  AUTOINT0`}",
              "PageCacheHitRatio" => 0.0,
              "PageCacheHits" => 0,
              "PageCacheMisses" => 0,
              "Rows" => 1,
              "Time" => 42285
            },
            "children" => [],
            "dbHits" => 0,
            "identifiers" => ["num"],
            "operatorType" => "Projection",
            "pageCacheHitRatio" => 0.0,
            "pageCacheHits" => 0,
            "pageCacheMisses" => 0,
            "rows" => 1
          }
        ],
        "dbHits" => 0,
        "identifiers" => ["num"],
        "operatorType" => "ProduceResults",
        "pageCacheHitRatio" => 0.0,
        "pageCacheHits" => 0,
        "pageCacheMisses" => 0,
        "rows" => 1
      },
      "t_last" => 0,
      "type" => "r"
    }
  ]

  describe "Response as Enumerable" do
    test "a simple query" do
      conn = Bolt.Sips.conn()
      response = Bolt.Sips.query!(conn, "RETURN 300 AS r")

      assert %Response{results: [%{"r" => 300}]} = response
      assert response |> Enum.member?("r")
      assert 1 = response |> Enum.count()
      assert [%{"r" => 300}] = response |> Enum.take(1)
      assert %{"r" => 300} = response |> Response.first()
    end

    @unwind %Bolt.Sips.Response{
      records: [[1], [2], [3], [4], [5], [6], '\a', '\b', '\t', '\n'],
      results: [
        %{"n" => 1},
        %{"n" => 2},
        %{"n" => 3},
        %{"n" => 4},
        %{"n" => 5},
        %{"n" => 6},
        %{"n" => 7},
        %{"n" => 8},
        %{"n" => 9},
        %{"n" => 10}
      ]
    }

    test "reduce: UNWIND range(1, 10) AS n RETURN n" do
      sum = Enum.reduce(@unwind, 0, &(&1["n"] + &2))
      assert 55 == sum
    end

    test "slice: UNWIND range(1, 10) AS n RETURN n" do
      slice = Enum.slice(@unwind, 0..2)
      assert [%{"n" => 1}, %{"n" => 2}, %{"n" => 3}] == slice
    end
  end

  describe "Success" do
    test "with valid EXPLAIN" do
      assert %Response{
               bookmark: nil,
               fields: ["n"],
               notifications: [],
               plan: %{
                 "args" => %{
                   "EstimatedRows" => 1.0,
                   "planner" => "COST",
                   "planner-impl" => "IDP",
                   "planner-version" => "3.5",
                   "runtime" => "INTERPRETED",
                   "runtime-impl" => "INTERPRETED",
                   "runtime-version" => "3.5",
                   "version" => "CYPHER 3.5"
                 },
                 "children" => [
                   %{
                     "args" => %{"EstimatedRows" => 1.0},
                     "children" => [],
                     "identifiers" => ["n"],
                     "operatorType" => "Create"
                   }
                 ],
                 "identifiers" => ["n"],
                 "operatorType" => "ProduceResults"
               },
               profile: nil,
               records: [],
               results: [],
               stats: [],
               type: "rw"
             } = Response.transform!(@explain)
    end

    test "with Notifications" do
      %Response{notifications: [notifications | _rest]} = Response.transform!(@notifications)

      assert %{
               "code" => "Neo.ClientNotification.Statement.CartesianProductWarning",
               "description" => "bad juju",
               "position" => %{"column" => 9, "line" => 1, "offset" => 8},
               "severity" => "WARNING",
               "title" => "This query builds a cartesian product between disconnected patterns."
             } = notifications
    end

    test "with Profile (without results)" do
      %Response{plan: nil, profile: profile, stats: stats} =
        Response.transform!(@profile_no_results)

      assert %{
               "args" => %{
                 "DbHits" => 0,
                 "EstimatedRows" => 1.0,
                 "PageCacheHitRatio" => 0.0,
                 "PageCacheHits" => 0,
                 "PageCacheMisses" => 0,
                 "Rows" => 0,
                 "planner" => "COST",
                 "planner-impl" => "IDP",
                 "planner-version" => "3.5",
                 "runtime" => "SLOTTED",
                 "runtime-impl" => "SLOTTED",
                 "runtime-version" => "3.5",
                 "version" => "CYPHER 3.5"
               },
               "children" => [
                 %{
                   "args" => %{
                     "DbHits" => 0,
                     "EstimatedRows" => 1.0,
                     "PageCacheHitRatio" => 0.0,
                     "PageCacheHits" => 0,
                     "PageCacheMisses" => 0,
                     "Rows" => 0
                   },
                   "children" => [
                     %{
                       "args" => %{
                         "DbHits" => 3,
                         "EstimatedRows" => 1.0,
                         "PageCacheHitRatio" => 0.0,
                         "PageCacheHits" => 0,
                         "PageCacheMisses" => 0,
                         "Rows" => 1
                       },
                       "children" => [],
                       "dbHits" => 3,
                       "identifiers" => ["n"],
                       "operatorType" => "Create",
                       "pageCacheHitRatio" => 0.0,
                       "pageCacheHits" => 0,
                       "pageCacheMisses" => 0,
                       "rows" => 1
                     }
                   ],
                   "dbHits" => 0,
                   "identifiers" => ["n"],
                   "operatorType" => "EmptyResult",
                   "pageCacheHitRatio" => 0.0,
                   "pageCacheHits" => 0,
                   "pageCacheMisses" => 0,
                   "rows" => 0
                 }
               ],
               "dbHits" => 0,
               "identifiers" => ["n"],
               "operatorType" => "ProduceResults",
               "pageCacheHitRatio" => 0.0,
               "pageCacheHits" => 0,
               "pageCacheMisses" => 0,
               "rows" => 0
             } = profile

      assert %{
               "labels-added" => 1,
               "nodes-created" => 1,
               "properties-set" => 1
             } = stats
    end

    test "with Profile (with results)" do
      %Response{plan: nil, profile: profile, stats: [], records: _records, results: results} =
        Response.transform!(@profile_results)

      assert %{
               "args" => %{
                 "DbHits" => 0,
                 "EstimatedRows" => 1.0,
                 "PageCacheHitRatio" => 0.0,
                 "PageCacheHits" => 0,
                 "PageCacheMisses" => 0,
                 "Rows" => 1,
                 "Time" => 25980,
                 "planner" => "COST",
                 "planner-impl" => "IDP",
                 "planner-version" => "3.5",
                 "runtime" => "COMPILED",
                 "runtime-impl" => "COMPILED",
                 "runtime-version" => "3.5",
                 "version" => "CYPHER 3.5"
               },
               "children" => [
                 %{
                   "args" => %{
                     "DbHits" => 0,
                     "EstimatedRows" => 1.0,
                     "Expressions" => "{num : $`  AUTOINT0`}",
                     "PageCacheHitRatio" => 0.0,
                     "PageCacheHits" => 0,
                     "PageCacheMisses" => 0,
                     "Rows" => 1,
                     "Time" => 42285
                   },
                   "children" => [],
                   "dbHits" => 0,
                   "identifiers" => ["num"],
                   "operatorType" => "Projection",
                   "pageCacheHitRatio" => 0.0,
                   "pageCacheHits" => 0,
                   "pageCacheMisses" => 0,
                   "rows" => 1
                 }
               ],
               "dbHits" => 0,
               "identifiers" => ["num"],
               "operatorType" => "ProduceResults",
               "pageCacheHitRatio" => 0.0,
               "pageCacheHits" => 0,
               "pageCacheMisses" => 0,
               "rows" => 1
             } = profile

      assert [%{"num" => 1}] = results
    end
  end
end
