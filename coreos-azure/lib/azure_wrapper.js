var _ = require('underscore');

var fs = require('fs');
var cp = require('child_process');

var yaml = require('js-yaml');

var openssl = require('openssl-wrapper');

var util = require('./util.js');

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
      if (task.current.length !== 0) {
        console.log('node_modules/azure-cli/bin/azure', task.current);
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
      } else {
        iter(pop_task());
      }
    }
  })(pop_task());
};

var save_state = function () {
  var file_name = util.join_output_file_path(conf.name, 'deployment.yml');
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

var create_ssh_key = function (prefix) {
  var opts = {
    x509: true,
    nodes: true,
    newkey: 'rsa:2048',
    subj: '/O=Weaveworks, Inc./L=London/C=GB/CN=weave.works',
    keyout: util.join_output_file_path(prefix, 'ssh.key'),
    out: util.join_output_file_path(prefix, 'ssh.pem'),
  };
  openssl.exec('req', opts, function (err, buffer) {
    if (err) console.log(err);
    fs.chmod(opts.keyout, '0600', function (err) {
      if (err) console.log(err);
    });
  });
  return {
    key: opts.keyout,
    pem: opts.out,
  }
}

var create_ssh_conf = function () {
  var file_name = util.join_output_file_path(conf.name, 'ssh_conf');
  var ssh_conf_head = [
    "Host *",
    "\tHostname " + conf.resources['service'] + ".cloudapp.net",
    "\tUser core",
    "\tCompression yes",
    "\tLogLevel FATAL",
    "\tStrictHostKeyChecking no",
    "\tUserKnownHostsFile /dev/null",
    "\tIdentitiesOnly yes",
    "\tIdentityFile " + conf.resources['ssh_key']['key'],
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
    '--location=West Europe',
    '--address-space=172.16.0.0',
    conf.resources['vnet'],
  ]);
};

exports.queue_machines = function (name_prefix, coreos_update_channel, cloud_config_creator) {
  var x = conf.nodes[name_prefix];
  var vm_create_base_args = [
    'vm', 'create',
    '--location=West Europe',
    '--connect=' + conf.resources['service'],
    '--virtual-network-name=' + conf.resources['vnet'],
    '--no-ssh-password',
    '--ssh-cert=' + conf.resources['ssh_key']['pem'],
  ];

  var cloud_config = cloud_config_creator(x, conf);

  var next_host = function (n) {
    hosts.ssh_port_counter += 1;
    var host = { name: util.hostname(n, name_prefix), port: hosts.ssh_port_counter };
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
    console.log(conf.old_size, n);
    if (conf.resizing && n < conf.old_size) {
      return [];
    } else {
      return vm_create_base_args.concat(next_host(n), [
        coreos_image_ids[coreos_update_channel], 'core',
      ]);
    }
  }));
};

exports.create_config = function (name, nodes) {
  conf = {
    name: name,
    nodes: nodes,
    weave_salt: util.rand_string(),
    resources: {
      vnet: [name, 'internal-vnet', util.rand_suffix].join('-'),
      service: [name, 'service-cluster', util.rand_suffix].join('-'),
      ssh_key: create_ssh_key(name),
    }
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

exports.load_state_for_resizing = function (state_file, node_type, new_nodes) {
  load_state(state_file);
  if (conf.hosts === undefined) {
    console.log('Nothing to look at.');
    process.abort();
  }
  conf.resizing = true;
  conf.old_size = conf.nodes[node_type];
  conf.old_state_file = state_file;
  conf.nodes[node_type] += new_nodes;
  hosts.collection = conf.hosts;
  hosts.ssh_port_counter += conf.hosts.length;
}