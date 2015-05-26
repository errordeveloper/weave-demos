#!/bin/bash

cd $(git rev-parse --show-toplevel)/felix

for i in 1 2 3 ; do
  hostname="es-${i}.weave.local"
  cmd="weave run --with-dns --hostname='${hostname}' --name='es' errordeveloper/weave-elasticsearch-minimal:latest"
  vm="core-0${i}"
  log="/tmp/vagrant_ssh_weave_${vm}"
  echo "Starting ElasticSearch on ${vm}..."

  vagrant ssh $vm --command "${cmd}" &> $log && echo "  - done" || echo "  - fail (see $log)"
done
