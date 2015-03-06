# Felix, a simple and flexible Vagrant template for Weave+CoreOS

![Felix](http://upload.wikimedia.org/wikipedia/commons/0/0f/Felix_the_cat.svg)

## About this cat

It's based on [coreos/coreos-vagrant](https://github.com/coreos/coreos-vagrant/), which is included within this repositroy. All Felix does is add `config.rb`.

With some basic logic in `config.rb`, he can append any number of `/etc/weave.#{HOSTNAME}.env` files to his own `cloud-config.yaml` and write out `user-data`, which he passed to Vagrant. He also generates some random strings that are used as weave network crypto salt for the lifetime of Vargant VMs. It's all kindda simple.

## How to use it

### Basic usage

```
git clone https://github.com/errordeveloper/weave-demos
cd weave-demos/felix
vagrant up
```

### Configuration

Felix will bring 3 box up by default. Each will have 1 CPU and 2G of RAM.

If you wish to overide the number of boxes:
```
echo '$num_instances=4' > config-override.rb
```

If your host doesn't have 8G of RAM to spare for the 4 boxes you are wanting:
```
echo '$vb_memory=512' >> config-override.rb
```

All other defaults are define by upstream [`Vagrantfile`](../coreos-vagrant/Vagrantfile#L11-L17).

## Next Steps

Once VMs are up, you can proceed to deploy Docker container on Weave.

Here is something simple you can try.

Firstly, launch a web server on one machine:
```
$ vagrant ssh core-01 -c 'sudo weave run --with-dns 10.0.0.1/24 --hostname=hola.weave.local errordeveloper/hello-weave'
Unable to find image 'errordeveloper/hello-weave:latest' locally
Pulling repository errordeveloper/hello-weave
...
Status: Downloaded newer image for errordeveloper/hello-weave:latest
007f00c857bb2559ed29cb713ba8cb88ff7ce2d23ec7f16231052bc0d6e92acc
Connection to 127.0.0.1 closed.
```
Then, attach a client container on the other and test it like so:
```
0 %> vagrant ssh core-02 
CoreOS stable (557.2.0)
Update Strategy: No Reboots
core@core-02 ~ $ docker attach `sudo weave run --with-dns 10.0.0.2/24 -ti errordeveloper/curl`
Unable to find image 'errordeveloper/curl:latest' locally
Pulling repository errordeveloper/curl
...
Status: Downloaded newer image for errordeveloper/curl:latest

/ # ping -c 3 hola.weave.local
PING hola.weave.local (10.0.0.1): 56 data bytes
64 bytes from 10.0.0.1: seq=0 ttl=64 time=2.635 ms
64 bytes from 10.0.0.1: seq=1 ttl=64 time=2.522 ms
64 bytes from 10.0.0.1: seq=2 ttl=64 time=3.134 ms

--- hola.weave.local ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 2.522/2.763/3.134 ms
/ #
/ # curl hola.weave.local:5000
Hello, Weave!
```

— Happy weaving with Felix!
