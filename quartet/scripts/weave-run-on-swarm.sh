#!/bin/sh -xe

weave_cidr=$1
shift 1

c=$(docker run --dns=172.17.42.1 $@)
## We need log ID or name, Swarm doesn't like short IDs whent it tries to match affinity expression
c=$(docker inspect --format='{{.Id}}' ${c})

#$WEAVE attach ${weave_cidr} ${c}

docker run --rm --privileged --net=host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /proc:/hostproc \
  -e PROCFS=/hostproc \
  -e "affinity:container==${c}" \
  weaveworks/weaveexec:0.10.0 --local attach ${weave_cidr} ${c}
