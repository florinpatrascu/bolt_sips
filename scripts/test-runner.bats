#!/usr/bin/env bats

# Inicializar la variable de entorno TEST_MODE=true antes de ejecutar las pruebas

# Load Bats
bats_helpers_root="${HOME_BATS}"
load "${bats_helpers_root}/bats-support/load.bash"
load "${bats_helpers_root}/bats-assert/load.bash"

# Load functions
load './test-runner.sh'

@test "find_services Devuelve servicios con boltVersion 1 y database neo4j" {
  run find_services "1.0" "neo4j"
  assert_success
  assert_output --partial "neo4j-3.4.0"
}

@test "find_services Devuelve servicios con boltVersion 5.1 y database neo4j" {
  run find_services "5.1" "neo4j"
  assert_success
  assert_output --partial "neo4j-5.12.0"
}

@test "find_services Devuelve error si falta boltVersion" {
  run find_services "" "neo4j"
  assert_failure
  assert_output --partial "Usage: find_services <boltVersion> <database>"
}

@test "find_services Devuelve error si falta database" {
  run find_services "5.1"
  assert_failure
  assert_output --partial "Usage: find_services <boltVersion> <database>"
}

@test "find_services Devuelve error si falta los parametros" {
  run find_services
  assert_failure
  assert_output --partial "Usage: find_services <boltVersion> <database>"
}

@test "find_services Devuelve cadena vacía si no se encuentran servicios" {
  run find_services "1" "otherengine"
  assert_success
  assert_output ""
}

@test "getAllBoltVersions Devuelve todos los valores de boltVersions sin repetir" {
  run getAllBoltVersions
  assert_success
  assert_output --partial "1.0"
  assert_output --partial "4.0"
  assert_output --partial "5.0"
  assert_output --partial "5.1"
  assert_output --partial "5.2"
  assert_output --partial "5.3"
}

@test "getAllDatabases Devuelve todos los valores de database sin repetir" {
  run getAllDatabases
  assert_success
  assert_output --partial "memgraph"
  assert_output --partial "neo4j"
}

@test "get_published_port para un servicio que no existe" {
  run get_published_port "servicio_inexistente"
  assert_success
  assert_output ""
}

@test "parse_array with comma-separated values" {
  run parse_array "1, 2, 3, 4"
  assert_success
  assert_output --partial "1 2 3 4"
}

@test "parse_array with comma-separated values (no spaces)" {
  run parse_array "1,2,3,4"
  assert_success
  assert_output --partial "1 2 3 4"
}

@test "parse_array with empty input" {
  run parse_array ""
  assert_output --partial ""
}

@test "parse_array with comma and space-separated values with special characters" {
  run parse_array "a, b c, d@e"
  assert_success
  assert_output --partial "a bc d@e"
}

@test "parse_param with comma and space-separated values" {
  run parse_param "1, 2, 3, 4"
  assert_success
  assert_output --partial "1 2 3 4"
}

@test "parse_param with comma-separated values (no spaces)" {
  run parse_param "1,2,3,4"
  assert_success
  assert_output --partial "1 2 3 4"
}

@test "parse_param with comma and space-separated values with databases" {
  run parse_param "neo4j, memgraph"
  assert_success
  assert_output --partial "neo4j memgraph"
}