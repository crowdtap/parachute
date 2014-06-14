var chalk = require('chalk');
var mout  = require('mout');

var lfit = function(str, len) {
  str = mout.string.truncate(str, len);
  str = mout.string.lpad(str, len);
  return str;
};

var rfit = function(str, len) {
  str = mout.string.truncate(str, len);
  str = mout.string.rpad(str, len);
  return str;
};

var prefix = chalk.gray('parachute');

module.exports = {
  info: function(locals) {
    var line = [
      prefix,
      chalk.cyan(rfit(locals.actor, 24)),
      chalk.green(lfit(locals.action, 9)),
      chalk.white(rfit(locals.detail, 24)),
      '\n'
    ];
    return line.join(' ');
  }
};
