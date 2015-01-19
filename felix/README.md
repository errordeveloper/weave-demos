# Felix, a simple and flexible Vagrant template for Weave+CoreOS

![Felix](http://upload.wikimedia.org/wikipedia/commons/0/0f/Felix_the_cat.svg)

## What exactly is it?

It's based on [coreos/coreos-vagrant](https://github.com/coreos/coreos-vagrant/), which is included within this repositroy. All Felix does is add `config.rb`.

With some basic logic in `config.rb`, he can append any number of `/etc/weave.#{HOSTNAME}.env` files to his own `cloud-config.yaml` and write out `user-data`, which he passed to Vagrant. He also generates some random strings that are used as weave network crypto salt for the lifetime of Vargant VMs. It's all kindda simple.
