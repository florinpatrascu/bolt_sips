#!/usr/bin/env bats

# Inicializar la variable de entorno TEST_MODE=true antes de ejecutar las pruebas

# Load Bats
bats_helpers_root="${HOME_BATS}"
load "/home/luis/bats-core/bats-support/load.bash"
load "/home/luis/bats-core/bats-assert/load.bash"

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
