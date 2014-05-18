var Q    = require('q');
var _    = require('lodash');
var fs   = require('fs');
var path = require('path');
var git  = require('./git-wrapper');

module.exports = {
  install: function() {
    var deferred = Q.defer();
    var config = JSON.parse(fs.readFileSync('./parachute.json'));

    var cacheDir = path.join(process.env.HOME, '.parachute');
    if (!fs.existsSync(cacheDir)) fs.mkdirSync(cacheDir);

    var cachePromises = [];
    for (var host in config) {
      var cacheDest;
      if (host.slice(0,4) === 'git@') {
        cacheDest = host.split(':')[1].split('/').join('-');
        if (cacheDest.slice(-4) === '.git') cacheDest = cacheDest.slice(0, -4);
      } else {
        cacheDest = _.last(host.split('/'));
      }

      var cacheTarget = path.join(cacheDir, cacheDest);
      var cachePromise = git(['clone', path.resolve(host), cacheTarget]);
      cachePromises.push(cachePromise);
    }

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
