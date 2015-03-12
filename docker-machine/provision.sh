#!/bin/sh -ex

DOCKER_MACHINE=${DOCKER_MACHINE:-"./docker-machine-v0.1.0"}

WEAVE_SCRIPT_URL="https://github.com/zettio/weave/releases/download/latest_release/weave"
WEAVE_SCRIPT_DST="/usr/local/sbin/weave"

for m in 'dev-1' 'dev-2'; do
        $DOCKER_MACHINE create -d virtualbox $m
        $DOCKER_MACHINE ssh $m "sudo curl --location --silent ${WEAVE_SCRIPT_URL} --output ${WEAVE_SCRIPT_DST}"
        $DOCKER_MACHINE ssh $m "sudo chmod +x ${WEAVE_SCRIPT_DST}"
        $DOCKER_MACHINE ssh $m "sudo weave launch"
done

sleep 3

$DOCKER_MACHINE ssh dev-2 "sudo weave connect $(./docker-machine-v0.1.0 ip dev-1)"

for m in 'dev-1' 'dev-2'; do
        $DOCKER_MACHINE ssh dev-1 "sudo weave status"
done
