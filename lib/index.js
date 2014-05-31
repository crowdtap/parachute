var fs      = require('fs');
var Manager = require('./Manager');

var commands = {
  install: function() {
    var config  = JSON.parse(fs.readFileSync('./parachute.json'));
    var manager = new Manager(config);
    return manager
      .cacheDependencies()
      .then(manager.deliverAssets.bind(manager));
  }
};

module.exports = commands;
