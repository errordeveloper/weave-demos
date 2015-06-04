#!/bin/bash -e

## This scrip is provides the ability to test different versions of
## Machine, Swarm and Docker binaries as well as Weave script
source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

head_node="${MACHINE_NAME_PREFIX}-1"

## Initial token to keep Machine happy
temp_swarm_dicovery_token="token://$(${DOCKER_SWARM_CREATE})"
swarm_flags="--swarm --swarm-discovery=${temp_swarm_dicovery_token}"

## Actual token to be used with proxied Docker
swarm_dicovery_token="token://$(${DOCKER_SWARM_CREATE})"

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
  export DOCKER_CLIENT_ARGS="$(${DOCKER_MACHINE} config)"

  ## We are going to use IPAM, hence we launch it with
  ## the following arguments
  $WEAVE launch -iprange 10.2.3.0/24 -initpeercount 3
  ## WeaveDNS also needs to be launched
  $WEAVE launch-dns "10.9.1.${i}/24" -debug
  ## And now the proxy
  $WEAVE launch-proxy --with-dns --with-ipam

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

$DOCKER ${DOCKER_CLIENT_ARGS} rm -f swarm-agent-master
$DOCKER ${DOCKER_CLIENT_ARGS} run -d --name=swarm-agent-master \
  -p 3376:3376 \
  swarm manage \
  -H "tcp://0.0.0.0:3376" ${swarm_dicovery_token}

## And make sure Weave cluster setup is comple
$WEAVE status
