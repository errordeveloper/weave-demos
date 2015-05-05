WEAVE=${WEAVE:-"$(git rev-parse --show-toplevel)/quartet/scripts/weave"}
DOCKER=${DOCKER:-"docker"}
DOCKER_MACHINE=${DOCKER_MACHINE:-"docker-machine"}
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
  $DOCKER pull errordeveloper/weaveexec-with-proxy-preview:latest
  $DOCKER tag errordeveloper/weaveexec-with-proxy-preview:latest zettio/weaveexec:latest
  $WEAVE launch
  $WEAVE launch-dns "10.9.1.${2}/24" -debug
  $DOCKER run \
    --privileged -d --name=weaveproxy \
    -p 12375:12375/tcp -v /var/run/docker.sock:/var/run/docker.sock \
    -v /proc:/hostproc -e PROCFS=/hostproc \
    --entrypoint=/home/weave/proxy zettio/weaveexec -debug
}

create_machine_with_simple_weave_setup() {
  $DOCKER_MACHINE_CREATE ${3} "${1}-${2}"
  eval `$DOCKER_MACHINE env "${1}-${2}"`
  $WEAVE launch
  $WEAVE launch-dns "10.9.1.${2}/24" -debug
}
