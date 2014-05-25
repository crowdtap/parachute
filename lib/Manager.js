var Q      = require('q');
var _      = require('lodash');
var fs     = require('fs');
var ncp    = require('ncp');
var url    = require('url');
var path   = require('path');
var walk   = require('walk');
var mkdirp = require('mkdirp');
var git    = require('./git-wrapper');

var Manager = (function() {
  var config, cacheDir;

  function Manager(_config) {
    config = _config;
    cacheDir = path.join(process.env.HOME, '.parachute');
    if (!fs.existsSync(cacheDir)) fs.mkdirSync(cacheDir);

    _.forOwn(config, function(val, host) {
      if (typeof val !== 'object') config[host] = {};
      config[host].root = config[host].root || './';
    });
  }

  Manager.prototype.cacheDependencies = function() {
    var cachePromises = _.map(config, function(val, host) {
      var cacheDest;
      var hostRepo = host;
      switch (host.slice(0,4)) {
        case 'git@':
          cacheDest = host.split(':')[1].split('/').join('-');
          break;
        case 'http':
          cacheDest = _.compact(url.parse(host).path.split('/')).join('-');
          break;
        default:
          hostRepo = path.resolve(host);
          cacheDest = _.last(host.split('/'));
      }
      if (cacheDest.slice(-4) === '.git') cacheDest = cacheDest.slice(0, -4);

      config[host].cache = path.join(cacheDir, cacheDest);

      if (fs.existsSync(config[host].cache)) {
        config[host].resolved = true;
        return true;
      }

      return git(['clone', hostRepo, config[host].cache])
               .then(function() { config[host].resolved = true; })
               .fail(function() { config[host].resolved = false; });
    });

    return Q.allSettled(cachePromises);
  };

  Manager.prototype.deliverAssets = function() {
    var ignoreRegexp = new RegExp(".*.log$|^\\..*|parachute.json");

    var deliverPromises = _.map(config, function(props) {
      if (props.resolved) {
        var deferred = Q.defer();

        var walker       = walk.walk(props.cache, { filters: ['.git'] });
        var walkPromises = [];

        walker.on('file', function(root, fileStats, next) {
          if (!_.isEmpty(fileStats.name.match(ignoreRegexp))) return next();

          var relRoot, src, dest;

          relRoot = path.relative(props.cache, root);
          relRoot = path.join(props.root, relRoot);
          src     = path.join(root, fileStats.name);
          dest    = path.join(process.cwd(), path.join(relRoot, fileStats.name));

          mkdirp(path.resolve(relRoot), function(err) {
            // TODO: Handle mkdirp errors
            if (err) throw err;
            walkPromises.push(Q.nfcall(ncp, src, dest));
            next();
          });
        });

        // TODO: Handle walker errors

        walker.on('end', function() {
          Q.allSettled(walkPromises).then(deferred.resolve);
        });

        return deferred.promise;
      } else {
        // TODO: Handle cache errors
      }
    });

    return Q.allSettled(deliverPromises);
  };

  Manager.prototype.resolve = function() {
    return this.cacheDependencies().then(this.deliverAssets);
  };

  return Manager;

})();

module.exports = Manager;
