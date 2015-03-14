#!/bin/sh -ex

DOCKER_MACHINE=${DOCKER_MACHINE:-"./docker-machine-v0.1.0"}

machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env $m); $@)
}

for m in 'dev-1' 'dev-2'; do
        $DOCKER_MACHINE create -d virtualbox $m
        machine_env $m ./weave launch
        machine_env $m ./weave launch-dns 10.20.0.1/24
done

sleep 3

machine_env 'dev-2' ./weave connect $($DOCKER_MACHINE ip 'dev-1')

for m in 'dev-1' 'dev-2'; do
        machine_env $m ./weave status
done
