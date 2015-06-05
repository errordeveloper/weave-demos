#!/bin/bash -xe

## NB: This is a very simple working prototype of how Weave can be used directly with Swarm,
## it is very basic and will be depricated once native Docker extensions land.

## IT IS RECOMMENDED TO USE PROXY-BASED APPROACH (SEE README).
## PLEASE DON'T USE THIS APPROACH UNLESS YOU KNOW WHAT YOU ARE DOING.

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

weave_cidr=$1
shift 1

c=$(docker run -d --dns=172.17.42.1 $@)

env WEAVEEXEC_DOCKER_ARGS="-e affinity:container==${c}" $WEAVE attach ${weave_cidr} ${c}
