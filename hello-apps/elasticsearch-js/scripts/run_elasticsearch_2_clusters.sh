#!/bin/bash

for t in 1 2; do
  team="team-${t}"
  for i in 1 2 3 ; do
    ip_addr="10.10.${t}.${i}/24"
    hostname="es-${i}.${team}.weave.local"
    cmd="sudo weave run --with-dns ${ip_addr} --hostname='${hostname}' --name='es-${team}' errordeveloper/weave-elasticsearch-minimal:latest"
    vm="core-0${i}"
    log="/tmp/vagrant_ssh_weave_${vm}_for_team_${t}"
    echo "Starting ElasticSearch on ${vm} for team ${t}..."
  
    vagrant ssh $vm --command "${cmd}" &> $log && echo "  - done" || echo "  - fail (see $log)"
  done
done
