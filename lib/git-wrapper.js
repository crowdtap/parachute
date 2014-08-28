var Q      = require('q');
var _      = require('lodash');
var path   = require('path');
var spawn  = require('child_process').spawn;

module.exports = function(repo, args, options) {
  var deferred = Q.defer();

  options = options || {};

  var defaults = {
    cwd:     process.cwd(),
    verbose: false
  };

  options = _.extend({}, defaults, options);

  var gitArgs   = _.flatten(['-C', path.resolve(repo), args]);
  var spawnArgs = _.omit(options, 'verbose');
  var child     = spawn('git', gitArgs, spawnArgs);

  child.on('exit', function(code) {
    if (code === 128) {
      deferred.reject("git did not exit cleanly");
    } else {
      deferred.resolve(code);
    }
  });

  child.stdout.on('data', function(data) {
    if (options.verbose) {
      deferred.notify(data.toString());
    }
  });

  child.stderr.on('data', function(data) {
    if (options.verbose) {
      deferred.notify(data.toString());
    }
  });

  return deferred.promise;
};
