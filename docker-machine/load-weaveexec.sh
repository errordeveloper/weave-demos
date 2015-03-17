#!/bin/sh -ex

DOCKER_MACHINE=${DOCKER_MACHINE:-"./docker-machine-v0.1.0"}

machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env $m); $@)
}

for m in 'dev-1' 'dev-2' 'dev-3'; do
  machine_env "${m}" docker load < weaveexec.tar
done
