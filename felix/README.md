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
