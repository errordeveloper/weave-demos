## Dependencies

The script bundled here assume you have following tools installed:

   - `docker` (at least the client)
   - VirtualBox
   - `docker-machine`
   - `docker-compose`

If you are using OS X, this is how you can install all 3 Docker tools:

```
brew install docker-machine docker-compose docker
```

## Setup
```
./scripts/setup-cluster.sh
```
## Basic Test
```
./scripts/on-swarm.sh \
  docker run -d \
    -e WEAVE_CIDR= \
    --hostname=hola.weave.local \
    errordeveloper/hello-weave;
./scripts/on-swarm.sh \
  docker run -ti \
    -e WEAVE_CIDR= \
    errordeveloper/curl;
```
## Compose Test
```
cd app/
../scripts/on-each-host.sh docker build -t app_web .
../scripts/on-swarm.sh docker-compose up -d
```
