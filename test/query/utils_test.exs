defmodule Bolt.Sips.Query.UtilsTest do
  use ExUnit.Case
  doctest Bolt.Sips.Query.Utils

  alias Bolt.Sips.Query

  describe "prepared_statement/2" do
    test "it creates a valid prepared statement, replacing the variables in place." do
      query = "MATCH ({{label}}) -[{{relation}}] -> () DELETE {{label}}, {{relation}}"
      parameters = [label: "Address", relation: "Sent"]

      prepared_query = Query.Utils.prepared_statement(query, parameters)

      assert prepared_query == "MATCH (Address) -[Sent] -> () DELETE Address, Sent"
    end

    test "it escapes parameters and returns a prepared statement" do
      query = "CREATE (s:Student) SET s.name = '{{student_name}}'"

      parameters = [
        student_name: "Robby' WITH DISTINCT true as haxxored MATCH (s:Student) DETACH DELETE s //"
      ]

      prepared_query = Query.Utils.prepared_statement(query, parameters)

      assert prepared_query ==
               "CREATE (s:Student) SET s.name = 'Robby\\' WITH DISTINCT true as haxxored MATCH (s:Student) DETACH DELETE s //'"
    end
  end
end
