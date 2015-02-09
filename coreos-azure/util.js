var _ = require('underscore');
_.mixin(require('underscore.string').exports());

var cp = require('child_process');

exports.hostname = function (n) {
  return _.template("<%= pre %>-<%= seq %>")({
    pre: 'core',
    seq: _.pad(n, 2, '0'),
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
