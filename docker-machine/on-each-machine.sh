#!/bin/sh -e

source defaults.sh

for m in $(${DOCKER_MACHINE} ls -q)
do (echo "${m}:"; with_machine_env ${m} "$@")
done
