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
var logger = require('./logger');

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
      isRemote:     true,
      resolved:     false,
      root:         clientConfig.root,
      slug:         '',
      treeish:      'master',
      url:          depUrl
    };
    _.merge(this, defaults);

    if (this.url.indexOf('#') > 0) {
      var tokens   = this.url.split('#');
      this.url     = tokens[0];
      this.treeish = tokens[1];
    }

    switch (this.url.slice(0,4)) {
      case 'git@':
        this.slug = this.url.split(':')[1].split('/').join('-');
        break;
      case 'http':
        this.slug = _.compact(url.parse(this.url).path.split('/')).join('-');
        break;
      default:
        this.isRemote = false;
        this.url = path.resolve(this.url);
        this.slug = _.last(this.url.split('/'));
    }
    if (this.slug.slice(-4) === '.git') this.slug = this.slug.slice(0, -4);

    this.cacheDir = path.join(this.cacheRoot, this.slug);
  }

  Dependency.prototype.cache = function() {
    function cacheSuccessHandler() {
      this.resolved = true;
    }

    function cacheFailureHandler() {
      this.resolved = false;
    }

    if (this.resolved || fs.existsSync(this.cacheDir)) {
      cacheSuccessHandler.apply(this);
      log.info({ actor: this.slug, action: 'cache', detail: 'existing' });
      return true;
    } else {
      log.info({ actor: this.slug, action: 'cache', detail: this.url });
      return git(process.cwd(), ['clone', this.url, this.cacheDir])
               .then(cacheSuccessHandler.bind(this), cacheFailureHandler.bind(this));
    }
  };

  Dependency.prototype.checkout = function() {
    function clean() { return git(this.cacheDir, ['clean', '-d', '-f']); }

    function update() {
      if (this.isRemote) {
        log.info({ actor: this.slug, action: 'update', detail: this.url });
        return git(this.cacheDir, ['pull']);
      } else {
        return true;
      }
    }

    function checkout() {
      var _treeish = this.treeish;
      log.info({ actor: this.slug, action: 'checkout', detail: _treeish });
      if (this.isRemote) _treeish = 'origin/' + this.treeish;

      return git(this.cacheDir, ['checkout', '-f', _treeish]);
    }

    return clean.call(this).then(update.bind(this)).then(checkout.bind(this));
  };

  Dependency.prototype.deliver = function() {
    if (!this.resolved) { /* TODO: Handle cache errors */ }
    var deferred = Q.defer();
    var ignoreRegexp = new RegExp(".*.log$|^\\..*|parachute.json");

    parseAssetManifest.call(this);

    var walker = walk.walk(this.cacheDir, { filters: ['.git'] });
    var walkPromises = [];

    walker.on('file', function(root, fileStats, next) {
      if (!_.isEmpty(fileStats.name.match(ignoreRegexp))) return next();

      var matchingSrcStr;
      var matchingDestStr;
      var src = path.join(root, fileStats.name);

      var mm = function(matcher) {
        if (_.isString(matcher)) {
          if (minimatch(src, path.join(this.cacheDir, matcher))) {
            matchingSrcStr = matcher;
            return true;
          }
        } else if (_.isPlainObject(matcher)) {
          return _.any(_.keys(matcher), function(key) {
            if (minimatch(src, path.join(this.cacheDir, key))) {
              matchingSrcStr = key;
              matchingDestStr = matcher[key];
              return true;
            }
          }.bind(this));
        }
      }.bind(this);

      var whitelisted = _.isEmpty(this.config.only) || _.isArray(this.config.only) && _.any(this.config.only, mm);
      var blacklisted = _.isArray(this.config.except) && _.any(this.config.except, mm);
      if (!whitelisted || blacklisted) return next();

      var relRoot = path.relative(this.cacheDir, root);

      // TODO: Clean all of this logic up
      if (matchingSrcStr) {
        // Preserve relative root for globs
        if (_.contains(matchingSrcStr, '**')) {
          var globbedBaseDir = path.join(this.cacheDir, matchingSrcStr.split('*')[0]);
          relRoot = path.relative(globbedBaseDir, root);
        }

        // Distinguish file from directory destinations
        if (_.last(matchingDestStr) === '/') {
          if (_.contains(matchingSrcStr, '**')) {
            relRoot = path.join(path.relative(process.cwd(), path.resolve(matchingDestStr)), relRoot);
          } else {
            relRoot = path.relative(process.cwd(), path.resolve(matchingDestStr));
          }
        } else if (matchingDestStr) {
          var baseDir = path.resolve(path.dirname(matchingDestStr));
          relRoot = path.relative(process.cwd(), baseDir);
        }
      }

      if (this.root) relRoot = path.join(this.root, relRoot);

      var relDest = path.join(relRoot, fileStats.name);
      var dest = path.join(process.cwd(), relDest);

      mkdirp(path.resolve(relRoot), function(err) {
        // TODO: Handle mkdirp errors
        if (err) throw err;
        log.info({ actor: this.slug, action: 'deliver', detail: relDest });
        walkPromises.push(Q.nfcall(ncp, src, dest));
        next();
      }.bind(this));
    }.bind(this));

    // TODO: Handle walker errors

    walker.on('end', function() {
      log.info({ actor: this.slug, action: 'deliver', detail: 'complete!' });
      Q.allSettled(walkPromises).then(deferred.resolve);
    }.bind(this));

    return deferred.promise;
  };


  // Helpers and private functions

  var log = {
    info: function(locals) {
      if (process.env.NODE_ENV !== 'test') logger.info(locals);
    }.bind(this)
  };

  function parseAssetManifest() {
    var hostConfigFile = path.join(this.cacheDir, 'parachute.json');
    if (fs.existsSync(hostConfigFile)) {
      try {
        this.hostConfig = JSON.parse(fs.readFileSync(hostConfigFile));
      } catch(e) {
        // TODO: Handle host config parse errors
      }

      // Set only/except directives
      this.config.only   = _.union(this.config.only, this.hostConfig.only);
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

  return Dependency;
})();

module.exports = Dependency;
