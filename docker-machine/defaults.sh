DOCKER_MACHINE=${DOCKER_MACHINE:-"./docker-machine-v0.2.0-rc3"}
DOCKER_MACHINE_CREATE="${DOCKER_MACHINE} create --driver virtualbox"

MACHINE_NAME_PREFIX=${MACHINE_NAME_PREFIX:-"dev"}

with_machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env "${m}"); $@)
}

create_machine_with_proxy_setup() {
  $DOCKER_MACHINE_CREATE "${1}-${2}"
  eval `$DOCKER_MACHINE env "${1}-${2}"`
  docker pull errordeveloper/weaveexec-with-proxy-preview:latest
  docker tag errordeveloper/weaveexec-with-proxy-preview:latest zettio/weaveexec:latest
  docker load < weavedns.tar
  ./weave launch
  ./weave launch-dns "10.9.1.${2}/24" -debug
  docker run \
    --privileged -d --name=weaveproxy \
    -p 12375:12375/tcp -v /var/run/docker.sock:/var/run/docker.sock \
    -v /proc:/hostproc -e PROCFS=/hostproc \
    --entrypoint=/home/weave/proxy zettio/weaveexec -debug
}
