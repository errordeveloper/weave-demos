#!/bin/bash

for i in 1 2 3 ; do
  ip_addr="10.10.1.${i}/24"
  hostname="es-${i}.weave.local"
  cmd="sudo weave run --with-dns ${ip_addr} --hostname='${hostname}' --name='es' errordeveloper/weave-elasticsearch-minimal:latest"
  vm="core-0${i}"
  log="/tmp/vagrant_ssh_weave_${vm}"
  echo "Starting ElasticSearch on ${vm}..."

  vagrant ssh $vm --command "${cmd}" &> $log && echo "  - done" || echo "  - fail (see $log)"
done
