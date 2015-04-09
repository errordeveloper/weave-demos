arch_suffix="$(uname -s)-$(uname -m)"
machine_version=${MACHINE_VERSION:-"0.2.0-rc3"}
compose_version=${COMPOSE_VERSION:-"1.1.0"}

curl --location --silent --output tools/docker-machine \
  https://github.com/docker/machine/releases/download/${machine_version}/docker-machine-${arch_suffix}
curl --location --silent --output tools/docker-compose \
  https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-${arch_suffix}

chmod +x tools/docker-machine
chmod +x tools/docker-compose
