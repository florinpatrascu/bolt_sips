#!/bin/bash
#
# Usage:
#   ./test.sh [-c COMMAND] [NAME1 [NAME2 [...]]]

# Dependencias:
#sudo apt-get install jq
# set -e

if [[ "$1" == "-c" ]]; then
  cmd="$2"
  shift
  shift
else
  cmd="mix test"
fi

if [[ "$@" == "" ]]; then
  services=`docker-compose config --services | xargs echo`
else
  services="$@"
fi

for name in $services; do
  port=`docker inspect --format='{{(index (index .NetworkSettings.Ports "7687/tcp") 0).HostPort}}' bolt_sips-${name}-1`
  echo $name  
done
