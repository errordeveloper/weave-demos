#!/bin/bash -ex

DOCKER_SWARM_CREATE=${DOCKER_SWARM_CREATE:-"docker-swarm create"}

## Actual token to be used with proxied Docker, different from the
## one we generated in intialy as Weave proxy listens on a different
## port and it's easier to just create a fresh token for this
swarm_dicovery_token="$(${DOCKER_SWARM_CREATE})"

for i in $(seq 3 | sort -r) ; do
  ## This environment variable is respected by Weave,
  ## hence it needs to be exported
  export DOCKER_CLIENT_ARGS="$(docker-machine config weave-${i})"
  ## Default Weave proxy port is 12375, we shall point
  ## Swarm agents at it next
  weave_proxy_endpoint="$(docker-machine ip):12375"

  ## Now we need restart Swarm agents like this
  docker ${DOCKER_CLIENT_ARGS} rm -f swarm-agent
  docker ${DOCKER_CLIENT_ARGS} run \
    -d \
    --restart=always \
    --name=swarm-agent \
    swarm join \
    --addr ${weave_proxy_endpoint} ${swarm_dicovery_token}

  if [ ${i} = 1 ] ; then
    ## On the head node (weave-1) we will also restart the Swarm master with the new token
    swarm_master_args_fmt="\
      -d \
      --restart=always \
      --name={{.Name}} \
      -p 3376:3376 \
      {{range .HostConfig.Binds}}-v {{.}} {{end}} \
      swarm{{range .Args}} {{.}}{{end}} \
    "

    swarm_master_args=$(docker ${DOCKER_CLIENT_ARGS} inspect \
        --format="${swarm_master_args_fmt}" \
        swarm-agent-master \
        | sed "s|\(token://\)[[:alnum:]]*|\1${swarm_dicovery_token}|")

    docker ${DOCKER_CLIENT_ARGS} rm -f swarm-agent-master
    docker ${DOCKER_CLIENT_ARGS} run ${swarm_master_args}

    ## And make sure Weave cluster setup is comple
    ./weave-dev status
  fi
done
