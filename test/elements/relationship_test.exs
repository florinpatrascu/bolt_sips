defmodule Relationship.Test do
  use ExUnit.Case, async: true
  doctest Bolt.Sips

  alias Bolt.Sips.Types.Relationship
  alias Bolt.Sips.{Response}

  # MATCH p=({name:'Alice'})-[r:KNOWS]->({name:'Bob'}) RETURN r
  @relationship [
    success: %{"fields" => ["r"]},
    record: [[sig: 82, fields: [1, 196, 197, "KNOWS", %{}]]],
    success: %{"type" => "r"}
  ]

  # MATCH p=()-[r:ACTED_IN]->() RETURN p LIMIT 2

  @match_acted_limit_2 [
    success: %{"fields" => ["p"]},
    record: [[sig: 80, fields: [[[sig: 78, fields: [501, ["Person"], %{"born" => 1964, "name" => "Keanu Reeves"}]], [sig: 78, fields: [663, ["Movie"], %{"released" => 2003, "title" => "Something's Gotta Give"}]]], [[sig: 114, fields: [474, "ACTED_IN", %{"roles" => ["Julian Mercer"]}]]], [1, 1]]]],
    record: [[sig: 80, fields: [[[sig: 78, fields: [501, ["Person"], %{"born" => 1964, "name" => "Keanu Reeves"}]], [sig: 78, fields: [609, ["Movie"], %{"released" => 1995, "tagline" => "The hottest data on earth. In the coolest head in town", "title" => "Johnny Mnemonic"}]]], [[sig: 114, fields: [385, "ACTED_IN", %{"roles" => ["Johnny Mnemonic"]}]]], [1, 1]]]],
    success: %{"type" => "r"}]


  # Find someone to introduce Tom Hanks to Tom Cruise
  # MATCH (tom:Person {name:'Tom Hanks'})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActors), (coActors)-[:ACTED_IN]->(m2)<-[:ACTED_IN]-(cruise:Person {name:'Tom Cruise'}) RETURN tom, m, coActors, m2, cruise "

  @co_actors [
    success: %{"fields" => ["tom", "m", "coActors", "m2", "cruise"]},
    record: [[sig: 78, fields: [580, ["Person"], %{"born" => 1956, "name" => "Tom Hanks"}]], [sig: 78, fields: [653, ["Movie"], %{"released" => 1995, "tagline" => "Houston, we have a problem.", "title" => "Apollo 13"}]], [sig: 78, fields: [519, ["Person"], %{"born" => 1958, "name" => "Kevin Bacon"}]], [sig: 78, fields: [513, ["Movie"], %{"released" => 1992, "tagline" => "In the heart of the nation's capital, in a courthouse of the U.S. government, one man will stop at nothing to keep his honor, and one will stop at nothing to find the truth.", "title" => "A Few Good Men"}]], [sig: 78, fields: [515, ["Person"], %{"born" => 1962, "name" => "Tom Cruise"}]]],
    record: [[sig: 78, fields: [580, ["Person"], %{"born" => 1956, "name" => "Tom Hanks"}]], [sig: 78, fields: [639, ["Movie"], %{"released" => 1999, "tagline" => "Walk a mile you'll never forget.", "title" => "The Green Mile"}]], [sig: 78, fields: [540, ["Person"], %{"born" => 1961, "name" => "Bonnie Hunt"}]], [sig: 78, fields: [537, ["Movie"], %{"released" => 2000, "tagline" => "The rest of his life begins now.", "title" => "Jerry Maguire"}]], [sig: 78, fields: [515, ["Person"], %{"born" => 1962, "name" => "Tom Cruise"}]]],
    record: [[sig: 78, fields: [580, ["Person"], %{"born" => 1956, "name" => "Tom Hanks"}]], [sig: 78, fields: [582, ["Movie"], %{"released" => 1993, "tagline" => "What if someone you never met, someone you never saw, someone you never knew was the only someone for you?", "title" => "Sleepless in Seattle"}]], [sig: 78, fields: [534, ["Person"], %{"born" => 1961, "name" => "Meg Ryan"}]], [sig: 78, fields: [528, ["Movie"], %{"released" => 1986, "tagline" => "I feel the need, the need for speed.", "title" => "Top Gun"}]], [sig: 78, fields: [515, ["Person"], %{"born" => 1962, "name" => "Tom Cruise"}]]],
    record: [[sig: 78, fields: [580, ["Person"], %{"born" => 1956, "name" => "Tom Hanks"}]], [sig: 78, fields: [587, ["Movie"], %{"released" => 1990, "tagline" => "A story of love, lava and burning desire.", "title" => "Joe Versus the Volcano"}]], [sig: 78, fields: [534, ["Person"], %{"born" => 1961, "name" => "Meg Ryan"}]], [sig: 78, fields: [528, ["Movie"], %{"released" => 1986, "tagline" => "I feel the need, the need for speed.", "title" => "Top Gun"}]], [sig: 78, fields: [515, ["Person"], %{"born" => 1962, "name" => "Tom Cruise"}]]],
    record: [[sig: 78, fields: [580, ["Person"], %{"born" => 1956, "name" => "Tom Hanks"}]], [sig: 78, fields: [576, ["Movie"], %{"released" => 1998, "tagline" => "At odds in life... in love on-line.", "title" => "You've Got Mail"}]], [sig: 78, fields: [534, ["Person"], %{"born" => 1961, "name" => "Meg Ryan"}]], [sig: 78, fields: [528, ["Movie"], %{"released" => 1986, "tagline" => "I feel the need, the need for speed.", "title" => "Top Gun"}]], [sig: 78, fields: [515, ["Person"], %{"born" => 1962, "name" => "Tom Cruise"}]]],
    success: %{"type" => "r"}
  ]

  test "finding someone to introduce Tom Hanks to Tom Cruise" do
    rows = Response.transform(@co_actors)
    assert length(rows) == 5

  end

  test "MATCH p=({name:'Alice'})-[r:KNOWS]->({name:'Bob'}) RETURN r" do
    row = Response.transform(@relationship)  |> List.first
    assert row == %{"r" => %Relationship{end: 197, id: 1, start: 196,
                                          properties: %{}, type: "KNOWS"}}
  end

  test "MATCH p=()-[r:ACTED_IN]->() RETURN p LIMIT 2" do
    paths = Response.transform(@match_acted_limit_2) |> Enum.map(&(&1["p"]))
    assert length(paths) == 2
  end
end
