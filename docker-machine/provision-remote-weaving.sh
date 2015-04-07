#!/bin/sh -ex

source defaults.sh

for i in '1' '2'; do
  m="${MACHINE_NAME_PREFIX}-${i}"
  $DOCKER_MACHINE_CREATE $m
  with_machine_env $m ./weave launch
  with_machine_env $m ./weave launch-dns "10.20.0.${i}/24"
done

sleep 3

with_machine_env 'dev-2' ./weave connect $($DOCKER_MACHINE ip 'dev-1')

for m in 'dev-1' 'dev-2'; do
        with_machine_env "${m}" ./weave status
done
