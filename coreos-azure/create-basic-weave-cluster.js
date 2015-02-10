#!/usr/bin/env node

var _ = require('underscore');

var util = require('./util.js');

var coreos_image_ids = {
  'stable': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-522.6.0',
};

var node_count = 3;

var resources = util.generate_azure_resource_strings('weave-cluster');

var cloud_config_file = util.create_basic_weave_cluster_cloud_config(node_count);

var vm_name_arg = _.template("--vm-name=<%= name %>")
var vm_ssh_port = _.template("--ssh=<%= port %>")

var initial_tasks = [
  ['network', 'vnet', 'create',
    '--location=West Europe',
    '--address-space=172.16.0.0',
    resources['vnet'],
  ],
];


var main_tasks = _(node_count).times(function (n) {
  return ['vm', 'create'].concat([
    '--location=West Europe',
    '--connect=' + resources['service'],
    '--virtual-network-name=' + resources['vnet'],
    '--custom-data=' + cloud_config_file,
    '--no-ssh-password',
    '--ssh-cert=../azure-linux/coreos/cluster/ssh-cert.pem',
    coreos_image_ids['stable'], 'core',
    vm_name_arg({ name: util.hostname(n) }),
    vm_ssh_port({ port: 2200 + n }),
  ]);
});

util.run_task_queue(initial_tasks.concat(main_tasks));
