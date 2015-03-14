#!/bin/sh -ex

DOCKER_MACHINE=${DOCKER_MACHINE:-"./docker-machine-v0.1.0"}
DOCKER_MACHINE_CREATE="${DOCKER_MACHINE} create --driver virtualbox"

WEAVE_SCRIPT_URL="https://github.com/zettio/weave/releases/download/latest_release/weave"
WEAVE_SCRIPT_DST="/usr/local/sbin/weave"

DOCKERHUB_USER="squaremo"
export DOCKERHUB_USER

machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env $m); $@)
}

#$DOCKER_MACHINE_CREATE 'dev-0'

## XXX: Looks like a bug in docker, all of this arrives at stdout:
#swarm:latest: The image you are pulling has been verified. Important: image verification is a tech preview feature and should not be relied on to provide security.
#Status: Downloaded newer image for swarm:latest
#5fd4686e8b1f8c285fac79d9a250345f

swarm_dicovery_token=$(machine_env 'dev-0' docker run swarm create | tail -1)
## Better version would be
#machine_env 'dev-0' docker run swarm create
#swarm_dicovery_token=$(machine_env 'dev-0' docker logs swarm)

swarm_flags="--swarm --swarm-discovery=token://${swarm_dicovery_token}"

$DOCKER_MACHINE_CREATE ${swarm_flags} --swarm-master 'dev-1'
machine_env 'dev-1' ./weave launch

for m in 'dev-2' 'dev-3'; do
        $DOCKER_MACHINE_CREATE ${swarm_flags} $m
        machine_env $m ./weave launch $($DOCKER_MACHINE ip 'dev-1')
done

sleep 3

for m in 'dev-1' 'dev-2' 'dev-3'; do
        machine_env $m ./weave status
done
