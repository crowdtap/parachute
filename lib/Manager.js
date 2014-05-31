var Q         = require('q');
var _         = require('lodash');
var fs        = require('fs');
var ncp       = require('ncp');
var url       = require('url');
var path      = require('path');
var walk      = require('walk');
var mkdirp    = require('mkdirp');
var minimatch = require('minimatch');
var git       = require('./git-wrapper');

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

      function cacheSuccessHandler() {
        config[host].resolved = true;
        var hostConfig = path.join(config[host].cache, 'parachute.json');
        if (fs.existsSync(hostConfig)) {
          try {
            config[host].config = JSON.parse(fs.readFileSync(hostConfig));
          } catch(e) {
            // TODO: Hande JSON parse errors
          }
        }
      }

      if (fs.existsSync(config[host].cache)) {
        cacheSuccessHandler();
        return true;
      }

      return git(['clone', hostRepo, config[host].cache])
               .then(cacheSuccessHandler)
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

          var relRoot, filepath, src, dest;

          relRoot  = path.join(props.root, path.relative(props.cache, root));
          filepath = path.join(relRoot, fileStats.name);
          src      = path.join(root, fileStats.name);
          dest     = path.join(process.cwd(), filepath);

          if (!_.isEmpty(props.config)) {
            var mm = function(matcher) {
              if (_.isString(matcher)) {
                return minimatch(filepath, matcher);
              } else if (_.isPlainObject(matcher)) {
                return _.any(_.keys(matcher), function(key) {
                  if (minimatch(filepath, key)) {
                    var destRoot = matcher[key];
                    relRoot  = path.join(destRoot, relRoot);
                    filepath = path.join(relRoot, fileStats.name);
                    dest     = path.join(process.cwd(), filepath);
                    return true;
                  }
                });
              }
            };

            var whitelisted = !props.config.only || _.isArray(props.config.only) && _.any(props.config.only, mm);
            var blacklisted = _.isArray(props.config.except) && _.any(props.config.except, mm);

            if (!whitelisted || blacklisted) return next();
          }

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
