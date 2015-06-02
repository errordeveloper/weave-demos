#!/bin/sh -e

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

head_node="${MACHINE_NAME_PREFIX}-1"

swarm_dicovery_token=$(docker-swarm create)

swarm_flags="--swarm --swarm-discovery=token://${swarm_dicovery_token}"

for i in '1' '2' '3'; do
  if [ ${i} = '1' ]; then
    $DOCKER_MACHINE_CREATE \
      ${swarm_flags} \
      --swarm-master \
      "${MACHINE_NAME_PREFIX}-${i}"
  else
    $DOCKER_MACHINE_CREATE \
      ${swarm_flags} \
      "${MACHINE_NAME_PREFIX}-${i}"
  fi

  export DOCKER_CLIENT_ARGS="$(${DOCKER_MACHINE} config)"

  $WEAVE launch
  $WEAVE launch-dns "10.9.1.${i}/24" -debug

  if [ ${i} -gt '1' ]; then
    $WEAVE connect $(DOCKER_MACHINE ip ${head_node})
  fi

  unset DOCKER_CLIENT_ARGS
done
