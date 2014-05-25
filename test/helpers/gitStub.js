var Q    = require('q');
var _    = require('lodash');
var fs   = require('fs');
var ncp  = require('ncp');
var path = require('path');

module.exports = function(args) {
  var deferred = Q.defer();
  var cmd = args[0];
  if (cmd === 'clone') {
    var src = args[1];
    var dest = args[2];

    if (fs.existsSync(dest)) {
      deferred.reject(new Error(dest + ' exists'));
    }

    if (src.match(/git@|http/i)) {
      var repo = _.last(src.split('/'));
      if (repo.slice(-4) === '.git') repo = repo.slice(0,-4);
      src = path.join('./repos', repo);
    }
    ncp(src, dest, { clobber: false, stopOnErr: true }, function(err) {
      if (err) {
        deferred.reject(true);
      } else {
        deferred.resolve(true);
      }
    });
  }

  return deferred.promise;
};
