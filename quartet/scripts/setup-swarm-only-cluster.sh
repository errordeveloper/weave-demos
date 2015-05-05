#!/bin/sh -ex

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

init_node="${MACHINE_NAME_PREFIX}-0"
head_node="${MACHINE_NAME_PREFIX}-1"

$DOCKER_MACHINE_CREATE ${init_node}

swarm_dicovery_token=$(with_machine_env ${init_node} docker run swarm create | tail -1)

swarm_flags="--swarm --swarm-discovery=token://${swarm_dicovery_token}"

$DOCKER_MACHINE rm -f ${init_node}

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
