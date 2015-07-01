---
title: Using Docker Machine with Weave 0.10
published: true
tags: docker, docker-machine, guide, automation, command-line
---

> ***This is an outdate guide, please find latest version on our website now!***  
> http://weave.works/guides/weave-and-docker-platform/index.html

In this post I'd like to show how quickly one can get up-and-running using [Weave](https://github.com/weaveworks/weave/) with [Docker Machine](https://github.com/docker/machine/). This was made possible with our latest [_v0.10.0_ release](https://github.com/weaveworks/weave/releases/tag/v0.10.0), which has many improvements including the ability to communicate with [remote Docker host](http://weaveblog.com/2015/04/20/remote-weaving-with-0-10/).

To follow this guide you will need to obtain the binaries for

- [***`docker` (at least the client)***](https://docs.docker.com/installation/#installation)
- [***`docker-machine`***](http://docs.docker.com/machine/#installation)
- [**VirtualBox**](https://www.virtualbox.org/wiki/Downloads)

If you are using OS X, then you can install these tools with Homebrew like this:

    brew install docker docker-machine

You will need to download and install VirtualBox manually as well, if you haven't done it yet. Please be sure to install latest version of Machine (_v0.2.0_), as there are some bugs in the previous release. You also want to use latest `boot2docker` VM image; you will get it if you haven't used Docker Machine previously on your computer, otherwise you should delete cached ISO image located in ***`~/.docker/machine/cache/boot2docker.iso`*** before you proceed.


## Let's proceed, it's only a few steps!

First, we will provision a VirtualBox VM with `docker-machine create`, then run Weave script again new VM and setup a few test containers.

    docker-machine create --driver=virtualbox weave-1
    curl --silent --location https://git.io/weave --output ./weave
    chmod +x ./weave
      
As I said, with Weave _v0.10.0_, you can run `weave` command agains a [remote Docker host](http://weaveblog.com/2015/04/20/remote-weaving-with-0-10/). You just need to make sure `DOCKER_HOST` environment variable is set, which `docker-machine env` does for you.

    eval `docker-machine env weave-1`

Now you can launch Weave router and WeaveDNS.

    ./weave launch
    ./weave launch-dns 10.30.50.1/24

Running containers is also as pretty simple.

First, the server:

    ./weave run --with-dns 10.5.2.1/24 \
       --hostname=hola.weave.local \
       errordeveloper/hello-weave
 
 Second a client:

    ./weave run --with-dns 10.5.2.2/24 \
        --hostname=test.weave.local \
        --name=test-client \
        --tty --interactive \
        errordeveloper/curl
   
 Now, let's test it out:

```
> docker attach test-client
    
test:/# ping -c 3 hola.weave.local
PING hola.weave.local (10.5.2.1): 56 data bytes
64 bytes from 10.5.2.1: seq=0 ttl=64 time=0.130 ms
64 bytes from 10.5.2.1: seq=1 ttl=64 time=0.204 ms
64 bytes from 10.5.2.1: seq=2 ttl=64 time=0.155 ms

--- hola.weave.local ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss

test:/# curl hola.weave.local:5000
Hello, Weave!
test:/# 
```

## What's next?

You can easily extend this setup to more then one Docker hosts, here is a hint (best to use a new terminal window).

    docker-machine create -d virtualbox weave-2
    eval `docker-machine env weave-2`
    ./weave launch
    ./weave launch-dns 10.30.50.2/24
    ./weave connect `docker-machine ip weave-1`
    ./weave run ... # what do you want to run?

Next I am planning to post a full guide on how to use Weave with Machine, Swarm and Compose all 4 together,  but you should also checkout [Ben Firshman's talk](https://clusterhq.com/blog/adding-compose-to-the-swarm-demo/) on how to use these as well as [Flocker](https://clusterhq.com). 

Do make sure to follow [@weaveworks](https://twitter.com/weaveworks), so you don't miss any new posts. You can always drop us a few lines to [team@weave.works](mailto:team@weave.works), to let us know what you think about Weave.