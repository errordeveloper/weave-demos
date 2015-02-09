var _ = require('underscore');
_.mixin(require('underscore.string').exports());

var fs = require('fs');
var cp = require('child_process');

var yaml = require('js-yaml');

var weave_salt = function make_weave_salt () {
  var crypto = require('crypto');
  var shasum = crypto.createHash('sha256');
  shasum.update(crypto.randomBytes(256));
  return shasum.digest('hex');
}();

exports.hostname = function hostname (n, prefix) {
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
  } catch (e) {
    console.log(e);
  }
};

var write_std_cloud_config_data = function (env_files) {
  var cloud_config = {};
  try {
    cloud_config = yaml.safeLoad(fs.readFileSync('./weave-cluster.yml', 'utf8'));
  } catch (e) {
    console.log(e);
  }
  cloud_config.write_files = env_files;
  write_cloud_config_from_object(cloud_config, './cloud-config.yml');
};

exports.write_std_cluster_cloud_config = function (node_count) {
  var std_env_file_template = {
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
      name: exports.hostname(n),
      dns_addr_cidr: 24,
      dns_addr_node: 10+n,
      dns_addr_base: '10.10.1',
      salt: weave_salt,
    };

    var elected_node = 0;
    if (n === elected_node) {
      weave_env.peers = "";
    } else {
      weave_env.peers = exports.hostname(elected_node);
    }

    var env_file = _.clone(std_env_file_template);
    env_file.path = env_file.path(weave_env);
    env_file.content = env_file.content(weave_env);

    return env_file;
  };

  write_std_cloud_config_data(_(node_count).times(make_node_config));
};

exports.write_kube_etcd_cloud_config = function (node_count) {

  var cloud_config = {
    "coreos": {
      "etcd": {
        "name":"etcd",
        "addr":"$private_ipv4:4001",
        "bind-addr":"0.0.0.0",
        "peer-addr":"$private_ipv4:7001",
        "snapshot":true,
        "max-retry-attempts":50,
      },
      "units": [{
          "name":"etcd.service",
          "command":"start",
      }],
      "update": {
        "group":"stable",
        "reboot-strategy":"off",
      },
    },
  };

  /*
  require('http').get("http://discovery.etcd.io/new", function(res) {
    res.setEncoding('utf8');
    res.on('data', function(data) {
      cloud_config.coreos.etcd.discovery = data;
      write_cloud_config_from_object(node_cloud_config, './kubernetes-etcd-nodes.yml');
    });
  });
  */

  var elected_node = 0;

  return _(node_count).times(function (n) {
    var node_cloud_config = _.clone(cloud_config);
    output_file = './etcd-node-' + n + '.yml';
    if (n !== elected_node) {
      node_cloud_config.coreos.etcd.peers = [
        exports.hostname(elected_node, 'etcd'), 7001
      ].join(':');
    }
    write_cloud_config_from_object(node_cloud_config, output_file);
    return output_file;
  });
};

exports.run_task_queue = function (given_tasks) {
  var tasks = {
    todo: given_tasks,
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
};
