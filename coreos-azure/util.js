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
    return generate_environment_file_entry_from_object(exports.hostname(n), {
      weavedns_addr: ipv4([10, 10, 1, 10+n], 24),
      weave_password: weave_salt,
      weave_peers: n === elected_node ? "" : exports.hostname(elected_node),
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
          exports.hostname(elected_node, 'etcd'), 7001
        ].join(':');
      }
      return cloud_config;
    });
  });
};

exports.create_kube_node_cloud_config = function (node_count) {
  var weave_env_file_template = {
    permissions: '0644',
    owner: 'root',
    content: _.template([
      'WEAVE_PEERS="<%= peers %>"',
      'BRIDGE_ADDRESS_CIDR="<%= cluster_addr_base %>.<%= docker_addr_node %>/<%= docker_addr_cidr %>"',
      'WEAVE_PASSWORD="<%= salt %>"',
      'BREAKOUT_ROUTE="<%= cluster_addr_base %>.<%= cluster_addr_pad %>/<%= cluster_addr_cidr %>"',
    ].join("\n")),
    path: _.template("/etc/weave.<%= name %>.env"),
  };

  var make_node_config = function (n) {
    var weave_env = {
      name: exports.hostname(n, 'kube'),
      cluster_addr_base: [10, 2].join('.'),
      cluster_addr_pad: [0, 0].join('.'),
      cluster_addr_cidr: 16,
      docker_addr_node: [n, 1].join('.'),
      docker_addr_cidr: 24,
      salt: weave_salt,
    };

    var elected_node = 0;
    if (n === elected_node) {
      weave_env.peers = "";
    } else {
      weave_env.peers = exports.hostname(elected_node, 'kube');
    }

    var env_file = _.clone(weave_env_file_template);
    env_file.path = env_file.path(weave_env);
    env_file.content = env_file.content(weave_env);

    return env_file;
  };

  return process_cloud_config_template('./kubernetes-cluster-main-nodes-template.yml',
      './kubernetes-cluster-main-nodes-generated.yml', function(cloud_config) {
    cloud_config.write_files = cloud_config.write_files.concat(_(node_count).times(make_node_config));
    return cloud_config;
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
