#!/bin/sh -e

source defaults.sh
export DOCKER_HOST=$(eval $($DOCKER_MACHINE env 'dev-1'); echo $DOCKER_HOST | sed 's/:2376/:2377/')
exec "$@"
