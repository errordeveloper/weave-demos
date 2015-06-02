#!/bin/sh -e

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

eval $(docker-machine env --swarm 'dev-1' | grep DOCKER_HOST)

exec "$@"
