#!/bin/bash -e

find_tls_args="cat /proc/\$(pgrep /usr/local/bin/docker)/cmdline | tr '\0' '\n' | grep ^--tls | tr '\n' ' '"

for i in $(seq 3) ; do
  ## This environment variable is respected by Weave script,
  ## hence it needs to be exported
  export DOCKER_CLIENT_ARGS="$(docker-machine config weave-${i})"

  for c in weave weavedns weaveexec ; do
    docker ${DOCKER_CLIENT_ARGS} load -i ~/Code/weave/${c}.tar
  done

  tlsargs=$(docker-machine ssh "weave-${i}" "${find_tls_args}")

  ## We are going to use IPAM, hence we launch it with
  ## the following arguments
  ./weave-dev launch -iprange 10.20.0.0/16 -initpeercount 3
  ## WeaveDNS also needs to be launched
  ./weave-dev launch-dns "10.53.1.${i}/24" -debug
  ## And now the proxy
  ./weave-dev launch-proxy --with-dns --with-ipam ${tlsargs}

  ## Let's connect-up the Weave cluster by telling
  ## each of the nodes about the head node (weave-1)
  if [ ${i} -gt 1 ] ; then
    ./weave-dev connect $(docker-machine ip 'weave-1')
  fi
done

unset DOCKER_CLIENT_ARGS
