#!/bin/bash
set -euo pipefail

# This script is used to run tests on different database versions
# using different versions of Bolt. You can customize the execution
# specifying the test command, Bolt versions and databases to use.

# Example of use:
# ./scripts/test-runner.sh -c "mix test" -b "1.0,5.2" -d "neo4j,memgraph"


if ! docker --version &> /dev/null
then
    echo "Docker is not installed or is not configured correctly."
    exit 1
fi

if ! docker-compose --version &> /dev/null
then
    echo "docker-compose is not installed or is not configured correctly."
    exit 1
fi

TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-120}
TEST_MODE=${TEST_MODE:-false}

readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly RED="\e[31m"
readonly RESET="\e[0m"
readonly CHECK_MARK="✔️"
readonly WARNING="⚠️"
readonly ERROR="❌"

function info_message() {
  local message="$1"
  local prefix=""
  
  if [ "$TEST_MODE" != "true" ]; then
    prefix="${GREEN}${CHECK_MARK} "
  fi

  echo -e "${prefix}Info: ${message}${RESET}"
}

function warning_message() {
  local message="$1"
  local prefix=""
  
  if [ "$TEST_MODE" != "true" ]; then
    prefix="${YELLOW}${WARNING} "
  fi
  echo -e "${prefix}Warning: ${message}${RESET}"
}

function error_message() {
  local message="$1"
  local prefix=""
  
  if [ "$TEST_MODE" != "true" ]; then
    prefix="${RED}${ERROR} "
  fi
  echo -e "${prefix}Error: ${message}${RESET}"
}


function find_services() {
  local boltVersion=""
  local database=""

  if [ $# -ne 2 ]; then
    error_message "Usage: find_services <boltVersion> <database>"
    return 1
  fi
  
  boltVersion="$1"
  database="$2"
  if [ -z "$boltVersion" ] || [ -z "$database" ]; then
    error_message "Usage: find_services <boltVersion> <database>"
    return 1
  fi
  local config_json
  config_json=$(docker-compose config --format=json)
  filtered_services=$(echo "$config_json" | jq --arg bv "$boltVersion" --arg db "$database" '
    .services | to_entries[] | select(
      (.value.labels.boltVersions | split(",") | index($bv)) and
      (.value.labels.database | split(",") | index($db))
    ) | .key
  ')
  echo $filtered_services
}

function getAllBoltVersions() {
  local bolt_versions=()
  local config_json
  config_json=$(docker-compose config --format json | jq -r '.services[] | .labels.boltVersions')
  
  IFS=',' read -ra bolt_versions <<< "$(echo -e "${config_json}" | tr ',' '\n' | sort -u | paste -s -d ',' -)"
  
  echo "${bolt_versions[@]}"
}

function getAllDatabases() {
  local databases=()
  local config_json
  config_json=$(docker-compose config --format json | jq -r '.services[] | .labels.database')
  
  IFS=$'\n' read -d '' -r -a databases <<< "$(echo -e "${config_json}" | sort -u | paste -s -)"
  
  echo "${databases[@]}"
}

function start_docker_service() {
  service=$1
  bash -c "docker-compose up -d $service"
}

function is_service_running?() {
  local service_name="$1"
  local json_output
  local published_port
  local timeout=$TIMEOUT_SECONDS
  local start_time=$(date +%s)
  local status="false"
  service_name=$(echo "$service_name" | tr -d '"')
  while true; do
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))
    if [ "$elapsed_time" -ge "$timeout" ]; then
      break
    fi
    json_output=$(docker-compose ps --status running --format json | jq -s .)    
    service=$(echo "$json_output" | jq --arg service_name "$service_name" -r '
      .[]
      | select(.Service == $service_name, .State == "running")'
    )   
    if [ -n "$service" ]; then
      status="true"
    else
      status="false"
    fi
    if [ "$status" = "true" ]; then
      break
    fi
    sleep 1
  done
  echo "${status}"
}

get_published_port() {
  local service_name=$1
  local json_output
  local published_port

  service_name=$(echo "$service_name" | tr -d '"')
  json_output=$(docker-compose ps --status running --format json | jq -s .)    
  published_port=$(echo "$json_output" | jq --arg sn "$service_name" -r '
    .[]
    | select(.Service == $sn)
    | .Publishers[]
    | select(.TargetPort == 7687)
    | .PublishedPort
  ')    
  echo $published_port
}

function parse_array() {
  local input="$1"
  local delimiter=","
  local cleaned_input=$(echo "$input" | tr -d ' ' | tr "$delimiter" "\n")
  array=($cleaned_input)
  echo "${array[@]}"
}

function parse_param() {
  local bolt_versions_argument="$1"
  local bolt_versions_array=($(parse_array "$bolt_versions_argument"))
  echo "${bolt_versions_array[@]}"
}

function main() {
  local command="mix test"
  local boltVersions=($(getAllBoltVersions))
  local databases=($(getAllDatabases))

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--command)
        shift
        command="$1"
        ;;
      -b|--boltVersion)
        shift
        boltVersions=($(parse_param "$1"))
        ;;
      -d|--databases)
        shift
        databases=($(parse_param "$1"))
        ;;
      *)
        error_message "Error: Parámetro desconocido: $1"
        exit 1
        ;;
    esac
    shift
  done

  info_message "Running command: $command"
  info_message "Bolt Versions: ${boltVersions[*]}"
  info_message "Databases: ${databases[*]}"

  for db in "${databases[@]}"; do
    for version in "${boltVersions[@]}"; do
      service=$(find_services "$version" "$db")
      service=$(echo "$service" | tr -d '"')
      if [ -n "$service" ]; then
        start_docker_service "$service"
        is_running=$(is_service_running? "$service")
        if [ "$is_running" = "true" ]; then
          port=$(get_published_port $service)
          if [ -n "$port" ]; then
            info_message "Tests for Service: "$service", Port ${port}, DB: ${db}, boltVersions: ${version}"
            BOLT_VERSIONS="${version}" BOLT_TCP_PORT=$port $command --only bolt_version:$version
          else
            warning_message "The PublishedPort port is null or not found. Service: "$service", DB: ${db}, boltVersions: ${boltVersions}"
          fi
        else
          warning_message "Tests were not executed because the service ${service} is not running."
        fi
      else
        warning_message "No service was found for the database $db and Bolt version $version."
      fi
    done
  done
}

if [ "$TEST_MODE" = "false" ]; then
  main "$@"
fi
