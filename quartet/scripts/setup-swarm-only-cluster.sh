#!/bin/sh -ex

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

head_node="${MACHINE_NAME_PREFIX}-1"

swarm_dicovery_token=$(docker-swarm create)

swarm_flags="--swarm --swarm-discovery=token://${swarm_dicovery_token}"

for i in '1' '2' '3'; do
  if [ ${i} = '1' ]; then
    create_machine_with_simple_weave_setup \
      "${MACHINE_NAME_PREFIX}" "${i}" "--swarm-master ${swarm_flags}" 
  else
    create_machine_with_simple_weave_setup \
      "${MACHINE_NAME_PREFIX}" "${i}" "${swarm_flags}"
    connect_to=$($DOCKER_MACHINE ip "${MACHINE_NAME_PREFIX}-${i}")
    with_machine_env ${head_node} $WEAVE connect ${connect_to}
  fi
done
