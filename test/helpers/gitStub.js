var Q    = require('q');
var _    = require('lodash');
var fs   = require('fs');
var ncp  = require('ncp');
var path = require('path');

var HEAD = 'master';

module.exports = function(args) {
  var cmd      = args[0];
  var gitStub  = {};

  gitStub.clean = function() {
    var deferred = Q.defer();
    setTimeout(function() {
      deferred.resolve(true);
    }, 5);
    return deferred.promise;
  };

  gitStub.pull = function() {
    var deferred = Q.defer();
    setTimeout(function() {
      deferred.resolve(true);
    }, 5);
    return deferred.promise;
  };

  gitStub.checkout = function(_args) {
    var deferred = Q.defer();
    setTimeout(function() {
      HEAD = _.last(_args);
      deferred.resolve(true);
    }, 5);
    return deferred.promise;
  };

  gitStub.clone = function(_args) {
    var deferred = Q.defer();
    if (fs.existsSync(dest)) deferred.reject(new Error(dest + ' exists'));

    var src = _args[1];
    var dest = _args[2];
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
    return deferred.promise;
  };

  // Test only helpers

  gitStub._HEAD = function() {
    return HEAD;
  };

  return gitStub[cmd](args);
};
