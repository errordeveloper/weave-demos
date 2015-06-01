---
title: Using Docker Machine and Swarm with Weave 0.10
published: true
tags: docker, docker-machine, docker-swarm, guide, automation, command-line
---

In this post I'd like to show how quickly one can get up-and-running using [Weave](https://github.com/weaveworks/weave/) with [Docker Machine](https://github.com/docker/machine/) and [Docker Swarm](https://github.com/docker/swarm). This was made possible with our latest [_v0.10.0_ release](https://github.com/weaveworks/weave/releases/tag/v0.10.0), which has many improvements, including the ability to communicate with [remote Docker hosts](http://weaveblog.com/2015/04/20/remote-weaving-with-0-10/). This guide builds on what was learned from [a previous post](http://blog.weave.works/2015/04/22/using-docker-machine-with-weave-0-10/), where I demonstrated how to use Weave with Docker Machine on a single host.

To follow this guide you will need to obtain the binaries for

- [***`docker` (at least the client)***](https://docs.docker.com/installation/#installation)
- [***`docker-machine`***](http://docs.docker.com/machine/#installation)
- [***`docker-swarm`***](http://docs.docker.com/swarm/#installation)
- [**VirtualBox**](https://www.virtualbox.org/wiki/Downloads)

If you are using OS X, then you can install these tools with Homebrew, via

    brew install docker docker-machine docker-swarm

You will need to download and install VirtualBox manually as well, if you haven't done it yet. Please be sure to install latest version of Machine (_v0.2.0_), as there are some bugs in the previous release. You also want to use latest `boot2docker` VM image; you will get it if you haven't used Docker Machine previously on your computer, otherwise you should delete the cached ISO image located in ***`~/.docker/machine/cache/boot2docker.iso`*** before you proceed.

## Let's go!

First, we need a few scripts. To get them, run

    git clone https://github.com/errordeveloper/weave-demos
    cd weave-demos/quartet

Now, we'll provision a cluster of 3 VMs. The following script will make sure all 3 VMs join the Swarm, and sets up the Weave network and WeaveDNS.

> If you've followed my previous guide, you'll need to clear the VMs you've previously created. Check the output of `docker-machine ls`, and delete them with `docker-machine rm -f <vm-name>`.

    ./scripts/setup-swarm-only-cluster.sh

Next, we need to make sure the right environment variables are set to talk to the Swarm master.

    eval `docker-machine env --swarm dev-1`

Although Weave _0.10.0_ can interact with remote Docker hosts, it doesn't yet work out of the box. So, I created a small script that does the right thing. Our _"Hello, Weave!"_ server can be launched like this:

    ./scripts/weave-run-on-swarm.sh 10.5.2.1/24 \
      --hostname=hola.weave.local \
      errordeveloper/hello-weave

And our client container can be launched in a very similar way:

    ./scripts/weave-run-on-swarm.sh 10.5.2.2/24 \
        --hostname=test.weave.local \
        --name=test-client \
        --tty --interactive \
        errordeveloper/curl

Now, let's test it out:

```
> docker attach test-client
    
test:/# ping -c 3 hola.weave.local
PING hola.weave.local (10.5.2.1): 56 data bytes
64 bytes from 10.5.2.1: seq=0 ttl=64 time=0.187 ms
64 bytes from 10.5.2.1: seq=1 ttl=64 time=0.119 ms
64 bytes from 10.5.2.1: seq=2 ttl=64 time=0.057 ms

--- hola.weave.local ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.057/0.121/0.187 ms
test:/# curl hola.weave.local:5000
Hello, Weave!
test:/# 
```

## What's next?

You can easily move the entire setup to run on a public cloud, with any of the many providers already available with Docker Machine.

For example, you can follow part of the [Azure guide](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-docker-machine/#create-the-certificate-and-key-files-for-docker-machine-and-azure) (setup steps 1, 2, and 3), and then set `DOCKER_MACHINE_DRIVER` like this:

    export DOCKER_MACHINE_DRIVER=" \
        --driver azure \
        --azure-subscription-id=SubscriptionID \
        --azure-subscription-cert=mycert.pem \
    "

Clean-up your local VMs, and re-run the cluster setup.

    docker-machine rm -f dev-1 dev-2 dev-3
    ./scripts/setup-swarm-only-cluster.sh
    eval `docker-machine env --swarm dev-1`
    ../scripts/weave-run-on-swarm.sh ... # what do you want to run?

Next, I am planning to post a full guide on how to use Weave with Machine, Swarm and Compose altogether.

Follow [@weaveworks](https://twitter.com/weaveworks), so you don't miss any new posts. And you can always drop us a few lines at [team@weave.works](mailto:team@weave.works), to let us know what you think about Weave.