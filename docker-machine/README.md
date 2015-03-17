## Setup
```
./provision-proxied-swarm.sh
```
## Test
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
