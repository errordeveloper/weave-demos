WEAVE=${WEAVE:-"$(git rev-parse --show-toplevel)/quartet/scripts/weave"}
DOCKER=${DOCKER:-"docker"}
DOCKER_MACHINE=${DOCKER_MACHINE:-"docker-machine"}
DOCKER_MACHINE_DRIVER=${DOCKER_MACHINE_DRIVER:-"--driver virtualbox"}
DOCKER_MACHINE_CREATE="${DOCKER_MACHINE} create ${DOCKER_MACHINE_DRIVER}"

MACHINE_NAME_PREFIX=${MACHINE_NAME_PREFIX:-"dev"}

with_machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env "${m}"); $@)
}

create_machine_with_proxy_setup() {
  $DOCKER_MACHINE_CREATE "${1}-${2}"
  eval `$DOCKER_MACHINE env "${1}-${2}"`
  $WEAVE launch -iprange 10.2.3.0/24
  $WEAVE launch-dns "10.9.1.${2}/24" -debug
  $WEAVE launch-proxy --with-dns --with-ipam
}

create_machine_with_simple_weave_setup() {
  $DOCKER_MACHINE_CREATE ${3} "${1}-${2}"
  eval `$DOCKER_MACHINE env "${1}-${2}"`
  $WEAVE launch
  $WEAVE launch-dns "10.9.1.${2}/24" -debug
}
