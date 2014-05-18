var Q      = require('q');
var _      = require('lodash');
var spawn  = require('child_process').spawn;

module.exports = function(args, options) {
  var deferred = Q.defer();

  options = options || {};

  var defaults = {
    cwd:     process.cwd(),
    verbose: false
  };

  options = _.extend({}, defaults, options);

  var child = spawn('git', args, _.omit(options, 'verbose'));

  child.on('exit', function(code) {
    if (code === 128) {
      deferred.reject("git did not exit cleanly");
    } else {
      deferred.resolve(code);
    }
  });

  child.stderr.on('data', function(data) {
    deferred.notify(data.toString());
  });

  return deferred.promise;
};
