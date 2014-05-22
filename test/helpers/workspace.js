var _ = require('lodash');
var fs     = require('fs');
var path   = require('path');
var mkdirp = require('mkdirp');

module.exports = {
  // Workspace environment setup
  //
  // ws:
  //   client:
  //     config: {} # client parachute.json 
  //   hosts: [
  //    {
  //      name: "" # directory name of repo
  //      config: {} # host parachute.json (optional)
  //      contents: {
  //        "name": "type" # name of item mappe to type [file|dir]
  //        ...
  //      }
  //    }
  //    ...
  //   ]
  setup: function(ws) {
    if (ws.client.config) {
      fs.writeFileSync('parachute.json', JSON.stringify(ws.client.config));
    }
    if (ws.hosts.length) {
      ws.hosts.forEach(function(host) {
        var repoPath = path.resolve('./repos/' + host.name);
        mkdirp.sync(repoPath);
        if (host.config) {
          var hostConfigFile = path.join(repoPath, 'parachute.json');
          fs.writeFileSync(hostConfigFile, JSON.stringify(host.config));
        }
        _.forOwn(host.contents, function(type, name) {
          var itemPath = path.resolve(repoPath, name);
          if (type === 'file') fs.writeFileSync(itemPath);
          if (type === 'dir')  fs.mkdirSync(itemPath);
        });
      });
    }
  }
};
