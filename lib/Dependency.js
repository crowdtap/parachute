var Q         = require('q');
var fs        = require('fs');
var url       = require('url');
var ncp       = require('ncp');
var path      = require('path');
var walk      = require('walk');
var _         = require('lodash');
var mkdirp    = require('mkdirp');
var minimatch = require('minimatch');

var git = require('./git-wrapper');

var Dependency = (function() {

  function Dependency(depUrl, clientConfig) {
    if (!_.isObject(clientConfig)) clientConfig = {};

    var defaults = {
      cacheDir:     '',
      cacheRoot:    path.join(process.env.HOME, '.parachute'),
      clientConfig: clientConfig,
      config:       {
        only:   clientConfig.only   || false,
        except: clientConfig.except || false
      },
      hostConfig:   {},
      resolved:     false,
      root:         clientConfig.root || './',
      url:          depUrl
    };
    _.merge(this, defaults);

    var cacheDest;
    switch (this.url.slice(0,4)) {
      case 'git@':
        cacheDest = this.url.split(':')[1].split('/').join('-');
        break;
      case 'http':
        cacheDest = _.compact(url.parse(this.url).path.split('/')).join('-');
        break;
      default:
        this.url = path.resolve(this.url);
        cacheDest = _.last(this.url.split('/'));
    }
    if (cacheDest.slice(-4) === '.git') cacheDest = cacheDest.slice(0, -4);

    this.cacheDir = path.join(this.cacheRoot, cacheDest);
  }

  Dependency.prototype.cache = function() {
    function cacheSuccessHandler() {
      this.resolved = true;
      var hostConfigFile = path.join(this.cacheDir, 'parachute.json');
      if (fs.existsSync(hostConfigFile)) {
        this.hostConfig = JSON.parse(fs.readFileSync(hostConfigFile));
        // TODO: Hande JSON parse errors

        // Set only/except directives
        this.config.only = _.union(this.config.only, this.hostConfig.only);
        this.config.except = _.union(this.config.except, this.hostConfig.except);

        // Parse group selections
        if (!_.isEmpty(this.clientConfig.groups) && !_.isEmpty(this.hostConfig.groups)) {
          var selected = _.pick(this.hostConfig.groups, function(groupAssets, groupName) {
            return _.contains(this.clientConfig.groups, groupName);
          }.bind(this));
          this.config.only = _.union(this.config.only, _.flatten(_.values(selected)));
        }
      }
    }

    if (this.resolved || fs.existsSync(this.cacheDir)) {
      cacheSuccessHandler.apply(this);
      return true;
    }

    return git(['clone', this.url, this.cacheDir])
             .then(cacheSuccessHandler.bind(this))
             .fail(function() { this.resolved = false; });
  };

  Dependency.prototype.deliver = function() {
    var deferred = Q.defer();
    var ignoreRegexp = new RegExp(".*.log$|^\\..*|parachute.json");
    var walker = walk.walk(this.cacheDir, { filters: ['.git'] });
    var walkPromises = [];

    if (!this.resolved) { /* TODO: Handle cache errors */ }

    walker.on('file', function(root, fileStats, next) {
      if (!_.isEmpty(fileStats.name.match(ignoreRegexp))) return next();

      var relRoot, filepath, src, dest;
      relRoot  = path.join(this.root, path.relative(this.cacheDir, root));
      filepath = path.join(relRoot, fileStats.name);
      src      = path.join(root, fileStats.name);
      dest     = path.join(process.cwd(), filepath);

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

      var whitelisted = _.isEmpty(this.config.only) || _.isArray(this.config.only) && _.any(this.config.only, mm);
      var blacklisted = _.isArray(this.config.except) && _.any(this.config.except, mm);
      if (!whitelisted || blacklisted) return next();

      mkdirp(path.resolve(relRoot), function(err) {
        // TODO: Handle mkdirp errors
        if (err) throw err;
        walkPromises.push(Q.nfcall(ncp, src, dest));
        next();
      });
    }.bind(this));

    // TODO: Handle walker errors

    walker.on('end', function() {
      Q.allSettled(walkPromises).then(deferred.resolve);
    });

    return deferred.promise;
  };

  return Dependency;
})();

module.exports = Dependency;
