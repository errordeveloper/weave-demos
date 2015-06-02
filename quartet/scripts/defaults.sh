WEAVE=${WEAVE:-"$(git rev-parse --show-toplevel)/quartet/scripts/weave"}
DOCKER=${DOCKER:-"docker"}
DOCKER_MACHINE=${DOCKER_MACHINE:-"docker-machine"}
DOCKER_MACHINE_DRIVER=${DOCKER_MACHINE_DRIVER:-"--driver virtualbox"}
DOCKER_MACHINE_CREATE="${DOCKER_MACHINE} create ${DOCKER_MACHINE_DRIVER}"
DOCKER_SWARM_CREATE=${DOCKER_SWARM_CREATE:-"docker-swarm create"}

MACHINE_NAME_PREFIX=${MACHINE_NAME_PREFIX:-"dev"}

with_machine_env() {
  m=$1
  shift 1
  (eval $($DOCKER_MACHINE env "${m}"); $@)
}
