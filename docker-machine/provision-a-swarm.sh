#!/bin/sh -ex

source defaults.sh

init_node='dev-0'
head_node='dev-1'

$DOCKER_MACHINE_CREATE ${init_node}

## XXX: Looks like a bug in docker, all of this arrives at stdout:
#swarm:latest: The image you are pulling has been verified. Important: image verification is a tech preview feature and should not be relied on to provide security.
#Status: Downloaded newer image for swarm:latest
#5fd4686e8b1f8c285fac79d9a250345f

swarm_dicovery_token=$(machine_env ${init_node} docker run swarm create | tail -1)
## Better version would be
#machine_env 'dev-0' docker run swarm create
#swarm_dicovery_token=$(machine_env 'dev-0' docker logs swarm)

swarm_flags="--swarm --swarm-discovery=token://${swarm_dicovery_token}"

$DOCKER_MACHINE_CREATE ${swarm_flags} --swarm-master ${head_node}
machine_env ${head_node} ./weave launch

for m in 'dev-2' 'dev-3'; do
  $DOCKER_MACHINE_CREATE ${swarm_flags} $m
  with_machine_env $m ./weave launch $($DOCKER_MACHINE ip ${head_node})
done

sleep 3

for m in '1' '2' '3'; do
  with_machine_env "dev-${m}" ./weave launch-dns "10.9.0.${m}/16"
done
