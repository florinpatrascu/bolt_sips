defmodule Relationship.Test do
  use ExUnit.Case, async: true
  doctest Bolt.Sips

  alias Bolt.Sips.Types.Relationship
  alias Bolt.Sips.{Response}

  # MATCH p=({name:'Alice'})-[r:KNOWS]->({name:'Bob'}) RETURN r
  @relationship [
    success: %{"fields" => ["r"]},
    record: [
      %Bolt.Sips.Types.Relationship{
        end: 197,
        id: 1,
        start: 196,
        properties: %{},
        type: "KNOWS"
      }
    ],
    success: %{"type" => "r"}
  ]

  # MATCH p=()-[r:ACTED_IN]->() RETURN p LIMIT 2

  @match_acted_limit_2 [
    success: %{"fields" => ["p"]},
    record: [
      %Bolt.Sips.Types.Path{
        nodes: [
          %Bolt.Sips.Types.Node{
            id: 3,
            labels: ["Person"],
            properties: %{"born" => 1969, "name" => "Renee Zellweger"}
          },
          %Bolt.Sips.Types.Node{
            id: 2,
            labels: ["Movie"],
            properties: %{
              "released" => 2000,
              "tagline" => "The rest of his life begins now.",
              "title" => "Jerry Maguire"
            }
          }
        ],
        relationships: [
          %Bolt.Sips.Types.UnboundRelationship{
            end: nil,
            id: 52,
            properties: %{"roles" => ["Dorothy Boyd"]},
            start: nil,
            type: "ACTED_IN"
          }
        ],
        sequence: [1, 1]
      }
    ],
    record: [
      %Bolt.Sips.Types.Path{
        nodes: [
          %Bolt.Sips.Types.Node{
            id: 6,
            labels: ["Person"],
            properties: %{"born" => 1962, "name" => "Kelly Preston"}
          },
          %Bolt.Sips.Types.Node{
            id: 2,
            labels: ["Movie"],
            properties: %{
              "released" => 2000,
              "tagline" => "The rest of his life begins now.",
              "title" => "Jerry Maguire"
            }
          }
        ],
        relationships: [
          %Bolt.Sips.Types.UnboundRelationship{
            end: nil,
            id: 53,
            properties: %{"roles" => ["Avery Bishop"]},
            start: nil,
            type: "ACTED_IN"
          }
        ],
        sequence: [1, 1]
      }
    ],
    success: %{"type" => "r"}
  ]

  # Find someone to introduce Tom Hanks to Tom Cruise
  # MATCH (tom:Person {name:'Tom Hanks'})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActors), (coActors)-[:ACTED_IN]->(m2)<-[:ACTED_IN]-(cruise:Person {name:'Tom Cruise'}) RETURN tom, m, coActors, m2, cruise "

  @co_actors [
    success: %{
      "fields" => ["tom", "m", "coActors", "m2", "cruise"]
    },
    record: [
      %Bolt.Sips.Types.Node{
        id: 209,
        labels: ["Person"],
        properties: %{"born" => 1956, "name" => "Tom Hanks"}
      },
      %Bolt.Sips.Types.Node{
        id: 286,
        labels: ["Movie"],
        properties: %{
          "released" => 1995,
          "tagline" => "Houston, we have a problem.",
          "title" => "Apollo 13"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 363,
        labels: ["Person"],
        properties: %{"born" => 1958, "name" => "Kevin Bacon"}
      },
      %Bolt.Sips.Types.Node{
        id: 359,
        labels: ["Movie"],
        properties: %{
          "released" => 1992,
          "tagline" =>
            "In the heart of the nation's capital, in a courthouse of the U.S. government, one man will stop at nothing to keep his honor, and one will stop at nothing to find the truth.",
          "title" => "A Few Good Men"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 360,
        labels: ["Person"],
        properties: %{"born" => 1962, "name" => "Tom Cruise"}
      }
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 209,
        labels: ["Person"],
        properties: %{"born" => 1956, "name" => "Tom Hanks"}
      },
      %Bolt.Sips.Types.Node{
        id: 272,
        labels: ["Movie"],
        properties: %{
          "released" => 1999,
          "tagline" => "Walk a mile you'll never forget.",
          "title" => "The Green Mile"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 88,
        labels: ["Person"],
        properties: %{"born" => 1961, "name" => "Bonnie Hunt"}
      },
      %Bolt.Sips.Types.Node{
        id: 78,
        labels: ["Movie"],
        properties: %{
          "released" => 2000,
          "tagline" => "The rest of his life begins now.",
          "title" => "Jerry Maguire"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 360,
        labels: ["Person"],
        properties: %{"born" => 1962, "name" => "Tom Cruise"}
      }
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 209,
        labels: ["Person"],
        properties: %{"born" => 1956, "name" => "Tom Hanks"}
      },
      %Bolt.Sips.Types.Node{
        id: 205,
        labels: ["Movie"],
        properties: %{
          "released" => 1998,
          "tagline" => "At odds in life... in love on-line.",
          "title" => "You've Got Mail"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 49,
        labels: ["Person"],
        properties: %{"born" => 1961, "name" => "Meg Ryan"}
      },
      %Bolt.Sips.Types.Node{
        id: 409,
        labels: ["Movie"],
        properties: %{
          "released" => 1986,
          "tagline" => "I feel the need, the need for speed.",
          "title" => "Top Gun"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 360,
        labels: ["Person"],
        properties: %{"born" => 1962, "name" => "Tom Cruise"}
      }
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 209,
        labels: ["Person"],
        properties: %{"born" => 1956, "name" => "Tom Hanks"}
      },
      %Bolt.Sips.Types.Node{
        id: 220,
        labels: ["Movie"],
        properties: %{
          "released" => 1990,
          "tagline" => "A story of love, lava and burning desire.",
          "title" => "Joe Versus the Volcano"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 49,
        labels: ["Person"],
        properties: %{"born" => 1961, "name" => "Meg Ryan"}
      },
      %Bolt.Sips.Types.Node{
        id: 409,
        labels: ["Movie"],
        properties: %{
          "released" => 1986,
          "tagline" => "I feel the need, the need for speed.",
          "title" => "Top Gun"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 360,
        labels: ["Person"],
        properties: %{"born" => 1962, "name" => "Tom Cruise"}
      }
    ],
    record: [
      %Bolt.Sips.Types.Node{
        id: 209,
        labels: ["Person"],
        properties: %{"born" => 1956, "name" => "Tom Hanks"}
      },
      %Bolt.Sips.Types.Node{
        id: 211,
        labels: ["Movie"],
        properties: %{
          "released" => 1993,
          "tagline" =>
            "What if someone you never met, someone you never saw, someone you never knew was the only someone for you?",
          "title" => "Sleepless in Seattle"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 49,
        labels: ["Person"],
        properties: %{"born" => 1961, "name" => "Meg Ryan"}
      },
      %Bolt.Sips.Types.Node{
        id: 409,
        labels: ["Movie"],
        properties: %{
          "released" => 1986,
          "tagline" => "I feel the need, the need for speed.",
          "title" => "Top Gun"
        }
      },
      %Bolt.Sips.Types.Node{
        id: 360,
        labels: ["Person"],
        properties: %{"born" => 1962, "name" => "Tom Cruise"}
      }
    ],
    success: %{"type" => "r"}
  ]

  test "finding someone to introduce Tom Hanks to Tom Cruise" do
    rows = Response.transform(@co_actors)
    assert length(rows) == 5
  end

  test "MATCH p=({name:'Alice'})-[r:KNOWS]->({name:'Bob'}) RETURN r" do
    row =
      Response.transform(@relationship)
      |> List.first()

    assert row == %{
             "r" => %Relationship{end: 197, id: 1, start: 196, properties: %{}, type: "KNOWS"}
           }
  end

  test "MATCH p=()-[r:ACTED_IN]->() RETURN p LIMIT 2" do
    paths = Response.transform(@match_acted_limit_2) |> Enum.map(& &1["p"])
    assert length(paths) == 2
  end
end
