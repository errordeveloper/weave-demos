#!/usr/bin/env node

var _ = require('underscore');

var fs = require('fs');

var util = require('./util.js');

var coreos_image_ids = {
  'stable': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-522.6.0',
};

var weave_salt = function make_weave_salt () {
  var crypto = require('crypto');
  var shasum = crypto.createHash('sha256');
  shasum.update(crypto.randomBytes(256));
  return shasum.digest('hex');
}();

var write_cloud_config_data = function (env_files) {
  try {
    var yaml = require('js-yaml');
    var cloud_config = yaml.safeLoad(fs.readFileSync('./weave-cluster.yml', 'utf8'));
    cloud_config.write_files = env_files;
    fs.writeFileSync('./cloud-config.yml', [
      '#cloud-config',
      yaml.safeDump(cloud_config),
    ].join("\n"));
  } catch (e) {
    console.log(e);
  }
};

var env_file_template = {
  permissions: '0644',
  owner: 'root',
  content: _.template([
    'WEAVE_PEERS="<%= peers %>"',
    'WEAVEDNS_ADDR="<%= dns_addr_base %>.<%= dns_addr_node %>/<%= dns_addr_cidr %>"',
    'WEAVE_PASSWORD="<%= salt %>"',
  ].join("\n")),
  path: _.template("/etc/weave.<%= name %>.env"),
};

var make_node_config = function (n) {
  var weave_env = {
    name: util.hostname(n),
    dns_addr_cidr: 24,
    dns_addr_node: 10+n,
    dns_addr_base: '10.10.1',
    salt: weave_salt,
  };

  var elected_node = 0;
  if (n === elected_node) {
    weave_env.peers = "";
  } else {
    weave_env.peers = util.hostname(elected_node);
  }

  var env_file = _.clone(env_file_template);
  env_file.path = env_file.path(weave_env);
  env_file.content = env_file.content(weave_env);
  
  return env_file;
};

var node_count = 3;

write_cloud_config_data(_(node_count).times(make_node_config));

var vm_name_arg = _.template("--vm-name=<%= name %>")
var vm_ssh_port = _.template("--ssh=<%= port %>")

var initial_tasks = [
  ['network', 'vnet', 'create',
    '--location=West Europe',
    '--address-space=172.16.0.0',
    'weave-cluster-internal-vnet-1',
  ],
];

var main_tasks = _(node_count).times(function (n) {
  return ['vm', 'create'].concat([
    '--location=West Europe',
    '--connect=weave-cluster-service-1',
    '--virtual-network-name=weave-cluster-internal-vnet-1',
    '--custom-data=./cloud-config.yml',
    '--no-ssh-password',
    '--ssh-cert=../azure-linux/coreos/cluster/ssh-cert.pem',
    coreos_image_ids['stable'], 'core',
    vm_name_arg({ name: util.hostname(n) }),
    vm_ssh_port({ port: 2200 + n }),
  ]);
});

util.run_task_queue(initial_tasks.concat(main_tasks));
