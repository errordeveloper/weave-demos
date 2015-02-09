#!/usr/bin/env node

var _ = require('underscore');

var util = require('./util.js');

var coreos_image_ids = {
  'stable': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-522.6.0',
};

var node_count = 3;

var nodes = {
  'etcd': 3,
}

util.write_std_cluster_cloud_config(node_count);

var vm_name_arg = _.template("--vm-name=<%= name %>")
var vm_ssh_port = _.template("--ssh=<%= port %>")

var initial_tasks = [
  ['network', 'vnet', 'create',
    '--location=West Europe',
    '--address-space=172.16.0.0',
    'weave-kubernetes-cluster-internal-vnet-1',
  ],
];

var vm_create_base_args = [
  'vm', 'create',
  '--location=West Europe',
  '--connect=weave-kubernetes-cluster-service-1',
  '--virtual-network-name=weave-kubernetes-cluster-internal-vnet-1',
  '--no-ssh-password',
  '--ssh-cert=../azure-linux/coreos/cluster/ssh-cert.pem',
];

var etcd_cloud_config_files = util.write_kube_etcd_cloud_config(nodes.etcd);

var create_etcd_cluster = _(nodes.etcd).times(function (n) {
  return vm_create_base_args.concat([
    '--custom-data=' + etcd_cloud_config_files[n],
    coreos_image_ids['stable'], 'core',
    vm_name_arg({ name: util.hostname(n, 'etcd') }),
    vm_ssh_port({ port: 2200 + n }),
  ]);
});

var create_kube_cluster = _(nodes.etcd).times(function (n) {
  return vm_create_base_args.concat([
    '--custom-data=kube-nodes.yml',
    coreos_image_ids['stable'], 'core',
    vm_name_arg({ name: util.hostname(n, 'kube') }),
    vm_ssh_port({ port: 2210 + n }),
  ]);
});

util.run_task_queue(initial_tasks.concat(create_etcd_cluster, create_kube_cluster));
