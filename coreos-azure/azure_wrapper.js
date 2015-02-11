var _ = require('underscore');
_.mixin(require('underscore.string').exports());

var fs = require('fs');
var cp = require('child_process');

var yaml = require('js-yaml');

var crypto = require('crypto');

var coreos_image_ids = {
  'stable': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-522.6.0',
  'alpha': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-584.0.0',
};

var conf = {};

var hosts = {
  collection: [],
  ssh_port_counter: 2200,
};

var task_queue = [];

var weave_salt = function () {
  var shasum = crypto.createHash('sha256');
  shasum.update(crypto.randomBytes(256));
  return shasum.digest('hex');
}();

var generate_azure_resource_strings = function (prefix) {
  var shasum = crypto.createHash('sha256');
  shasum.update(crypto.randomBytes(256));
  var rand_suffix = shasum.digest('hex').substring(50);
  return {
    vnet: [prefix, 'internal-vnet', rand_suffix].join('-'),
    service: [prefix, 'service-cluster', rand_suffix].join('-'),
  }
};

var hostname = function hostname (n, prefix) {
  return _.template("<%= pre %>-<%= seq %>")({
    pre: prefix || 'core',
    seq: _.pad(n, 2, '0'),
  });
};

var write_cloud_config_from_object = function (cloud_config, output_file) {
  try {
    fs.writeFileSync(output_file, [
      '#cloud-config',
      yaml.safeDump(cloud_config),
    ].join("\n"));
    return output_file;
  } catch (e) {
    console.log(e);
  }
};

var process_cloud_config_template = function (input_file, output_file, processor) {
  var cloud_config = {};
  try {
    cloud_config = yaml.safeLoad(fs.readFileSync(input_file, 'utf8'));
  } catch (e) {
    console.log(e);
  }
  return write_cloud_config_from_object(processor(_.clone(cloud_config)), output_file);
};

var generate_environment_file_entry_from_object = function (hostname, environ) {
  var data = {
    hostname: hostname,
    environ_array: _.map(environ, function (value, key) {
      return [key.toUpperCase(), JSON.stringify(value.toString())].join('=');
    }),
  };

  return {
    permissions: '0600',
    owner: 'root',
    content: _.template("<%= environ_array.join('\\n') %>\n")(data),
    path: _.template("/etc/weave.<%= hostname %>.env")(data),
  };
};

var ipv4 = function (ocets, prefix) {
  return {
    ocets: ocets,
    prefix: prefix,
    toString: function () {
      return [ocets.join('.'), prefix].join('/');
    }
  }
}

var write_basic_weave_cluster_cloud_config = function (env_files) {
  return process_cloud_config_template('./basic-weave-cluster-template.yml',
      './basic-weave-cluster-generated.yml', function(cloud_config) {
    cloud_config.write_files = env_files;
    return cloud_config;
  });
};

exports.create_basic_weave_cluster_cloud_config = function (node_count) {
  var elected_node = 0;

  var make_node_config = function (n) {
    return generate_environment_file_entry_from_object(hostname(n), {
      weavedns_addr: ipv4([10, 10, 1, 10+n], 24),
      weave_password: weave_salt,
      weave_peers: n === elected_node ? "" : hostname(elected_node),
    });
  };

  return write_basic_weave_cluster_cloud_config(_(node_count).times(make_node_config));
};

exports.create_kube_etcd_cloud_config = function (node_count) {
  var elected_node = 0;

  return _(node_count).times(function (n) {
    var output_file = './kubernetes-cluster-etcd-node-' + n + '-generated.yml';
    return process_cloud_config_template('./kubernetes-cluster-etcd-node-template.yml',
        output_file, function(cloud_config) {
      if (n !== elected_node) {
        cloud_config.coreos.etcd.peers = [
          hostname(elected_node, 'etcd'), 7001
        ].join(':');
      }
      return cloud_config;
    });
  });
};

exports.create_kube_node_cloud_config = function (node_count) {
  var elected_node = 0;

  var make_node_config = function (n) {
    return generate_environment_file_entry_from_object(hostname(n, 'kube'), {
      weave_password: weave_salt,
      weave_peers: n === elected_node ? "" : hostname(elected_node, 'kube'),
      breakout_route: ipv4([10, 2, 0, 0], 16),
      bridge_address_cidr: ipv4([10, 2, n, 1], 24),
    });
  };

  return process_cloud_config_template('./kubernetes-cluster-main-nodes-template.yml',
      './kubernetes-cluster-main-nodes-generated.yml', function(cloud_config) {
    cloud_config.write_files = cloud_config.write_files.concat(_(node_count).times(make_node_config));
    return cloud_config;
  });
};

exports.run_task_queue = function (dummy) {
  var tasks = {
    todo: task_queue,
    done: [],
  };

  var pop_task = function() {
    console.log(tasks);
    var ret = {};
    ret.current = tasks.todo.shift();
    ret.remaining = tasks.todo.length;
    return ret;
  };

  (function iter (task) {
    if (task.current === undefined) {
      if (conf.destroying === undefined) {
        create_ssh_conf();
        save_state();
      }
      return;
    } else {
      //console.log('node_modules/azure-cli/bin/azure', task.current);
      cp.fork('node_modules/azure-cli/bin/azure', task.current)
        .on('exit', function (code, signal) {
          tasks.done.push({
            code: code,
            signal: signal,
            what: task.current.join(' '),
            remaining: task.remaining,
          });
          if (code !== 0 && conf.destroying === undefined) {
            console.log("Exiting due to an error.");
            save_state();
            console.log("You probably want to destroy and re-run.");
            process.abort();
          } else {
            iter(pop_task());
          }
      });
    }
  })(pop_task());
};

var save_state = function () {
  var file_name = conf.name + '_deployment.yml';
  try {
    conf.hosts = hosts.collection;
    fs.writeFileSync(file_name, yaml.safeDump(conf));
    console.log('Saved state into `%s`', file_name);
  } catch (e) {
    console.log(e);
  }
};

var load_state = function (file_name) {
  try {
    conf = yaml.safeLoad(fs.readFileSync(file_name, 'utf8'));
    console.log('Loaded state from `%s`', file_name);
    return conf;
  } catch (e) {
    console.log(e);
  }
};

var create_ssh_conf = function () {
  var file_name = conf.name + '_ssh_conf';
  var ssh_conf_head = [
    "Host *",
    "\tHostname " + conf.resources['service'] + ".cloudapp.net",
    "\tUser core",
    "\tCompression yes",
    "\tLogLevel FATAL",
    "\tStrictHostKeyChecking no",
    "\tUserKnownHostsFile /dev/null",
    "\tIdentitiesOnly=yes",
    "\n",
  ];

  fs.writeFileSync(file_name, ssh_conf_head.concat(_.map(hosts.collection, function (host) {
    return _.template("Host <%= name %>\n\tPort <%= port %>\n")(host);
  })).join('\n'));
  console.log('Saved SSH config, you can use it like so: `ssh -F ', file_name, '<hostname>`');
  console.log('The hosts in this deployment are:\n', _.map(hosts.collection, function (host) { return host.name; }));
};

exports.queue_default_network = function () {
  task_queue.push([
    'network', 'vnet', 'create',
    '--verbose',
    '--location=West Europe',
    '--address-space=172.16.0.0',
    conf.resources['vnet'],
  ]);
};

exports.queue_machines = function (name_prefix, coreos_update_channel, cloud_config_creator) {
  var x = conf.nodes[name_prefix];
  var vm_create_base_args = [
    'vm', 'create',
    '--verbose',
    '--location=West Europe',
    '--connect=' + conf.resources['service'],
    '--virtual-network-name=' + conf.resources['vnet'],
    '--no-ssh-password',
    '--ssh-cert=../azure-linux/coreos/cluster/ssh-cert.pem',
  ];

  var cloud_config = cloud_config_creator(x);

  var next_host = function (n) {
    hosts.ssh_port_counter += 1;
    var host = { name: hostname(n, name_prefix), port: hosts.ssh_port_counter };
    if (cloud_config instanceof Array) {
      host.cloud_config_file = cloud_config[n];
    } else {
      host.cloud_config_file = cloud_config;
    }
    hosts.collection.push(host);
    return _.map([
        "--vm-name=<%= name %>",
        "--ssh=<%= port %>",
        "--custom-data=<%= cloud_config_file %>",
    ], function (arg) { return _.template(arg)(host); });
  };

  task_queue = task_queue.concat(_(x).times(function (n) {
    return vm_create_base_args.concat(next_host(n), [
      coreos_image_ids[coreos_update_channel], 'core',
    ]);
  }));
};

exports.create_config = function (name, nodes) {
  conf = {
    name: name,
    nodes: nodes,
    resources: generate_azure_resource_strings(name),
  };
};

exports.destroy_cluster = function (state_file) {
  load_state(state_file);
  if (conf.hosts === undefined) {
    console.log('Nothing to delete.');
    process.abort();
  }

  conf.destroying = true;
  task_queue = _.map(conf.hosts, function (host) {
    return ['vm', 'delete', '--quiet', '--blob-delete', host.name];
  });

  task_queue.push(['network', 'vnet', 'delete', '--quiet', conf.resources['vnet']]);

  exports.run_task_queue();
};
