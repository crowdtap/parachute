var Q       = require('Q');
var fs      = require('fs');
var Manager = require('./Manager');

var commands = {
  install: function() {
    var deferred = Q.defer();
    var config   = JSON.parse(fs.readFileSync('./parachute.json'));
    var manager  = new Manager(config);

    manager
      .cacheDependencies()
      .then(manager.deliverAssets.bind(manager))
      .then(deferred.resolve)
      .progress(deferred.notify)
      .fail(deferred.reject);

    return deferred.promise;
  }
};

module.exports = commands;
