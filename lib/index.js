var Q    = require('q');
var _    = require('lodash');
var fs   = require('fs');
var url  = require('url');
var path = require('path');
var git  = require('./git-wrapper');

module.exports = {
  install: function() {
    var deferred = Q.defer();
    var config = JSON.parse(fs.readFileSync('./parachute.json'));

    var cacheDir = path.join(process.env.HOME, '.parachute');
    if (!fs.existsSync(cacheDir)) fs.mkdirSync(cacheDir);

    var cachePromises = _.map(config, function(val, host) {
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

      var cacheTarget = path.join(cacheDir, cacheDest);
      return git(['clone', path.resolve(host), cacheTarget]);
    });

    Q.allSettled(cachePromises).then(function(results) {
      results.forEach(function(result) {
        if (result.state === 'fulfilled') {
          // do something
        } else {
          // do something else
        }
      });
      deferred.resolve();
    });

    return deferred.promise;
  }
};
