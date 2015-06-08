#!/bin/bash -xe

## DEVELOPMENT VERSION OF `setup-cluster.sh`, YOU SHOULD PROBABLY
## USE `setup-cluster.sh`, UNLESS YOU KNOW WHAT YOU ARE DOING.

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

WEAVE="${WEAVE}-dev"

head_node="${MACHINE_NAME_PREFIX}-1"

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
      "${MACHINE_NAME_PREFIX}-${i}"
  else
    ## The rest of machines are Swarm slaves
    $DOCKER_MACHINE_CREATE \
      ${swarm_flags} \
      "${MACHINE_NAME_PREFIX}-${i}"
  fi

  ## This environment variable is respected by Weave,
  ## hence it needs to be exported
  export DOCKER_CLIENT_ARGS="$($DOCKER_MACHINE config)"

  for c in weave weavedns weaveexec; do
    docker ${DOCKER_CLIENT_ARGS} load -i ~/Code/weave/${c}.tar
  done

  tlsargs=$($DOCKER_MACHINE ssh "${MACHINE_NAME_PREFIX}-${i}" "${find_tls_args}")

  ## We are going to use IPAM, hence we launch it with
  ## the following arguments
  $WEAVE launch -iprange 10.2.3.0/24 -initpeercount 3
  ## WeaveDNS also needs to be launched
  $WEAVE launch-dns "10.9.1.${i}/24" -debug
  ## And now the proxy
  $WEAVE launch-proxy --with-dns --with-ipam ${tlsargs}

  ## Let's connect-up the Weave cluster by telling
  ## each of the node about the head node
  if [ ${i} -gt '1' ]; then
    $WEAVE connect $($DOCKER_MACHINE ip ${head_node})
  fi

  ## Default Weave proxy port is 12375, we shall point
  ## Swarm agents at it next
  weave_proxy_endpoint="$($DOCKER_MACHINE ip):12375"

  ## Now we need restart Swarm agents like this
  $DOCKER ${DOCKER_CLIENT_ARGS} rm -f swarm-agent
  $DOCKER ${DOCKER_CLIENT_ARGS} run -d --name=swarm-agent \
    swarm join \
    --addr ${weave_proxy_endpoint} ${swarm_dicovery_token}

done

## Next we will also restart the Swarm master with the new token
export DOCKER_CLIENT_ARGS=$($DOCKER_MACHINE config ${head_node})

swarm_master_args_fmt='-d --name={{.Name}} -p 3376:3376 {{range .HostConfig.Binds}}-v {{.}} {{end}}swarm{{range .Args}} {{.}}{{end}}'

swarm_master_args=$($DOCKER ${DOCKER_CLIENT_ARGS} inspect \
    --format="${swarm_master_args_fmt}" \
    swarm-agent-master \
  | sed "s|${temp_swarm_dicovery_token}|${swarm_dicovery_token}|")

$DOCKER ${DOCKER_CLIENT_ARGS} rm -f swarm-agent-master
$DOCKER ${DOCKER_CLIENT_ARGS} run ${swarm_master_args}

## And make sure Weave cluster setup is comple
$WEAVE status
