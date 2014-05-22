var Q    = require('q');
var _    = require('lodash');
var ncp  = require('ncp');
var path = require('path');

module.exports = function(args) {
  var cmd = args[0];
  if (cmd === 'clone') {
    var src = args[1];
    var dest = args[2];
    if (src.match(/git@|http/i)) {
      var repo = _.last(src.split('/'));
      if (repo.slice(-4) === '.git') repo = repo.slice(0,-4);
      src = path.join('./repos', repo);
    }
    return Q.nfcall(ncp, src, dest);
  }
};
