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
      // var val = config[host];
      var cacheTarget = path.join(cacheDir, _.last(host.split('/')));
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
