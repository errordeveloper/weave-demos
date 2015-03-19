#!/bin/sh -ex

DOCKER_MACHINE=${DOCKER_MACHINE:-"./docker-machine-v0.1.0"}
DOCKER_MACHINE_CREATE="${DOCKER_MACHINE} create --driver virtualbox"

machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env $m); $@)
}

for i in '1' '2' '3' '4'; do
  m="dev-${i}"
  $DOCKER_MACHINE_CREATE "${m}"
  machine_env "${m}" docker pull errordeveloper/weaveexec-with-proxy-preview:latest
  machine_env "${m}" docker tag errordeveloper/weaveexec-with-proxy-preview:latest zettio/weaveexec:latest
  machine_env "${m}" ./weave launch
  machine_env "${m}" ./weave launch-dns "10.9.1.${i}/24" -debug
  machine_env "${m}" docker run \
    --privileged -d --name=weaveproxy \
    -p 12375:12375/tcp -v /var/run/docker.sock:/var/run/docker.sock \
    -v /proc:/hostproc -e PROCFS=/hostproc \
    --entrypoint=/home/weave/proxy zettio/weaveexec -debug
done

for m in 'dev-2' 'dev-3' 'dev-4'; do
  machine_env 'dev-1' ./weave connect $($DOCKER_MACHINE ip "${m}")
done

swarm_dicovery_token=$(machine_env 'dev-1' docker run swarm create | tail -1)

for m in 'dev-1' 'dev-2' 'dev-3' 'dev-4'; do
  ip=$($DOCKER_MACHINE ip "${m}")
  machine_env "${m}" docker run -d swarm \
    join --addr "${ip}:12375" "token://${swarm_dicovery_token}"
done

machine_env 'dev-4' docker run -d -p 2377:2377 swarm \
  manage -H 0.0.0.0:2377 "token://${swarm_dicovery_token}"
