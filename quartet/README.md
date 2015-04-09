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
./provision-proxied-swarm.sh
```
## Basic Test
```
export DOCKER_HOST=tcp://$(./docker-machine-v0.1.0 ip dev-4):2377
docker run -d \
  -e WEAVE_CIDR=10.20.20.1/24 \
  --hostname=hola.weave.local \
  --dns=172.17.42.1 \
  errordeveloper/hello-weave;
docker run -ti \
  -e WEAVE_CIDR=10.20.20.2/24 \
  --dns=172.17.42.1 \
  errordeveloper/curl;
```
## Compose Test
```
./on-each-machine.sh docker build -t app_web app/
cd app/
export DOCKER_HOST=$(eval $($DOCKER_MACHINE env 'dev-1'); echo $DOCKER_HOST | sed 's/:2376/:2377/')
```
