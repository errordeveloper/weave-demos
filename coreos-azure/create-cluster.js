#!/usr/bin/env node

var _ = require('underscore');
_.mixin(require('underscore.string').exports());

var fs = require('fs');
var cp = require('child_process');

var coreos_image_ids = {
  'stable': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-522.6.0',
};

var AzureCli = require('azure-cli');
var cli = new AzureCli();

process.argv.shift(2);

var weave_salt = function make_weave_salt () {
  var crypto = require('crypto');
  var shasum = crypto.createHash('sha256');
  shasum.update(crypto.randomBytes(256));
  return shasum.digest('hex');
}();

var hostname = function (n) {
  return _.template("<%= pre %>-<%= seq %>")({
    pre: 'core',
    seq: _.pad(n, 2, '0'),
  });
};

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
    name: hostname(n),
    dns_addr_cidr: 24,
    dns_addr_node: 10+n,
    dns_addr_base: '10.10.1',
    salt: weave_salt,
  };

  elected_node = 0;
  if (n === elected_node) {
    weave_env.peers = "";
  } else {
    weave_env.peers = hostname(elected_node);
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


var tasks = {
  todo: _(node_count).times(function (n) {
    return ['vm', 'create'].concat([
        '--custom-data=./cloud-config.yml',
        '--no-ssh-password',
        '--ssh-cert=../azure-linux/coreos/cluster/ssh-cert.pem',
        '--connect=weave-testing-1', '--location=West Europe',
        coreos_image_ids['stable'], 'core',
        vm_name_arg({ name: hostname(n) }),
        vm_ssh_port({ port: 2200 + n }),
      ]);
  }),
  done: [],
};

var pop_task = function() {
  var ret = {};
  ret.current = tasks.todo.shift();
  ret.remaining = tasks.todo.length;
  console.log(tasks);
  return ret;
};

(function iter (task) {
  if (task.current === undefined) {
    return;
  } else {
    cp.fork('node_modules/azure-cli/bin/azure', task.current)
      .on('exit', function (code, signal) {
        tasks.done.push({
          code: code,
          signal: signal,
          what: task.current.join(' '),
          remaining: task.remaining,
        });
        iter(pop_task());
    });
  }
})(pop_task());
