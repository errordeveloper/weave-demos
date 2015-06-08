#!/bin/bash -e

head_node="weave-1"

DOCKER_MACHINE_DRIVER=${DOCKER_MACHINE_DRIVER:-"--driver virtualbox"}
DOCKER_MACHINE_CREATE="docker-machine create ${DOCKER_MACHINE_DRIVER}"
DOCKER_SWARM_CREATE=${DOCKER_SWARM_CREATE:-"docker-swarm create"}

## Initial token to keep Machine happy
temp_swarm_dicovery_token="token://$(${DOCKER_SWARM_CREATE})"
swarm_flags="--swarm --swarm-discovery=${temp_swarm_dicovery_token}"

## Actual token to be used with proxied Docker
swarm_dicovery_token="token://$(${DOCKER_SWARM_CREATE})"

find_tls_args="cat /proc/\$(pgrep /usr/local/bin/docker)/cmdline | tr '\0' '\n' | grep ^--tls | tr '\n' ' '"

for i in '1' '2' '3'; do
  if [ ${i} = '1' ]; then
    ## The first machine shall be the Swarm master
    $DOCKER_MACHINE_CREATE \
      ${swarm_flags} \
      --swarm-master \
      "weave-${i}"
  else
    ## The rest of machines are Swarm slaves
    $DOCKER_MACHINE_CREATE \
      ${swarm_flags} \
      "weave-${i}"
  fi

  ## This environment variable is respected by Weave,
  ## hence it needs to be exported
  export DOCKER_CLIENT_ARGS="$(docker-machine config)"

  for c in weave weavedns weaveexec; do
    docker ${DOCKER_CLIENT_ARGS} load -i ~/Code/weave/${c}.tar
  done

  tlsargs=$(docker-machine ssh "weave-${i}" "${find_tls_args}")

  ## We are going to use IPAM, hence we launch it with
  ## the following arguments
  weave launch -iprange 10.20.0.0/16 -initpeercount 3
  ## WeaveDNS also needs to be launched
  weave launch-dns "10.53.1.${i}/24" -debug
  ## And now the proxy
  weave launch-proxy --with-dns --with-ipam ${tlsargs}

  ## Let's connect-up the Weave cluster by telling
  ## each of the node about the head node
  if [ ${i} -gt '1' ]; then
    weave connect $(docker-machine ip ${head_node})
  fi

  ## Default Weave proxy port is 12375, we shall point
  ## Swarm agents at it next
  weave_proxy_endpoint="$(docker-machine ip):12375"

  ## Now we need restart Swarm agents like this
  docker ${DOCKER_CLIENT_ARGS} rm -f swarm-agent
  docker ${DOCKER_CLIENT_ARGS} run -d --name=swarm-agent \
    swarm join \
    --addr ${weave_proxy_endpoint} ${swarm_dicovery_token}

done

## Next we will also restart the Swarm master with the new token
export DOCKER_CLIENT_ARGS=$(docker-machine config ${head_node})

swarm_master_args_fmt='-d --name={{.Name}} -p 3376:3376 {{range .HostConfig.Binds}}-v {{.}} {{end}}swarm{{range .Args}} {{.}}{{end}}'

swarm_master_args=$(docker ${DOCKER_CLIENT_ARGS} inspect \
    --format="${swarm_master_args_fmt}" \
    swarm-agent-master \
  | sed "s|${temp_swarm_dicovery_token}|${swarm_dicovery_token}|")

docker ${DOCKER_CLIENT_ARGS} rm -f swarm-agent-master
docker ${DOCKER_CLIENT_ARGS} run ${swarm_master_args}

## And make sure Weave cluster setup is comple
weave status
