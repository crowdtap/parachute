var Q    = require('q');
var _    = require('lodash');
var fs   = require('fs');
var ncp  = require('ncp');
var url  = require('url');
var path = require('path');
var git  = require('./git-wrapper');

var Manager = (function() {
  var config, cacheDir;

  function Manager(_config) {
    config = _config;
    cacheDir = path.join(process.env.HOME, '.parachute');
    if (!fs.existsSync(cacheDir)) fs.mkdirSync(cacheDir);
  }

  function cacheDependencies() {
    var cachePromises = _.map(config, function(val, host) {
      if (typeof val !== 'object') config[host] = {};

      var cacheDest;
      switch (host.slice(0,4)) {
        case 'git@':
          cacheDest = host.split(':')[1].split('/').join('-');
          break;
        case 'http':
          cacheDest = _.compact(url.parse(host).path.split('/')).join('-');
          break;
        default:
          cacheDest = _.last(host.split('/'));
      }
      if (cacheDest.slice(-4) === '.git') cacheDest = cacheDest.slice(0, -4);

      config[host].cache = path.join(cacheDir, cacheDest);

      var promise = git(['clone', path.resolve(host), config[host].cache])
          .then(function() { config[host].resolved = true; })
          .fail(function() { config[host].resolved = false; });

      return promise;
    });
    return Q.allSettled(cachePromises);
  }

  function deliverAssets() {
    var deliverPromises = _.map(config, function(props) {
      if (props.resolved) {
        return Q.nfcall(fs.readdir, props.cache).then(function(files) {
          var ncpPromises = _.map(files, function(file) {
            var src = path.join(props.cache, file);
            var dest = path.join(process.cwd(), file);
            return Q.nfcall(ncp, src, dest);
          });
          return Q.allSettled(ncpPromises);
        });
      } else {
        // Did not cache properly
      }
    });

    return Q.allSettled(deliverPromises);
  }

  Manager.prototype.resolve = function() {
    return cacheDependencies().then(deliverAssets);
  };

  return Manager;

})();

module.exports = Manager;
