#!/bin/sh -e

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

for m in $(${DOCKER_MACHINE} ls -q)
do (echo "${m}:"; with_machine_env ${m} "$@")
done
