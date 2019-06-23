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

  @profile [
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

    test "with Profile" do
      %Response{plan: plan} = Response.transform!(@profile)

      assert %{
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
             } = plan
    end
  end
end
