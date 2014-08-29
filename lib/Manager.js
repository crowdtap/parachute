var Q    = require('q');
var fs   = require('fs');
var path = require('path');
var _    = require('lodash');

var Dependency = require('./Dependency');

var Manager = (function() {

  function Manager(config) {
    var cacheDir = path.join(process.env.HOME, '.parachute');
    if (!fs.existsSync(cacheDir)) fs.mkdirSync(cacheDir);

    this.dependencies = _.map(config, function(hostConfig, url) {
      return new Dependency(url, hostConfig);
    });
  }

  Manager.prototype.cacheDependencies = function() {
    var caches = _.map(this.dependencies, function(dep) {
      return dep.cache();
    });
    return Q.allSettled(caches);
  };

  Manager.prototype.deliverAssets = function() {
    var deliveries = _.map(this.dependencies, function(dep) {
      return dep.checkout().then(dep.deliver.bind(dep));
    });

    return Q.allSettled(deliveries);
  };

  return Manager;
})();

module.exports = Manager;
