/* jshint expr:true */

var chai           = require('chai');
var chaiAsPromised = require('chai-as-promised');
var expect         = chai.expect;
chai.use(chaiAsPromised);

var _      = require('lodash');
var fs     = require('fs');
var path   = require('path');
var rimraf = require('rimraf');
var rewire = require('rewire');

var gitStub   = require('./helpers/gitStub');
var workspace = require('./helpers/workspace');

var managerStub = rewire('../lib/Manager');
managerStub.__set__('git', gitStub);

var parachute = rewire('../lib');
parachute.__set__('Manager', managerStub);

var hosts = require('./hosts');

describe('#install', function() {
  var cwd          = process.cwd();
  var testDir      = __dirname + '/tmp';
  process.env.HOME = testDir;

  beforeEach(function(done) {
    rimraf(testDir, function(err) {
      if (err) throw err;
      fs.mkdir(testDir, function(err) {
        if (err) throw err;
        process.chdir(testDir);
        done();
      });
    });
  });

  afterEach(function(done) {
    process.chdir(cwd);
    rimraf(testDir, function(err) {
      if (err) throw new Error('Unable to remove test directory');
      done();
    });
  });

  describe('caching', function() {
    it('caches local asset host repositories', function() {
      var ws = {
        client: {
          config: { "./repos/no-config-1": true }
        },
        hosts: [ hosts.noConfig1 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'no-config-1'))).to.be.ok;
      });
    });

    it('caches remote ssh host repositories', function() {
      var ws = {
        client: {
          config: { "git@github.com:example/no-config-1.git": true }
        },
        hosts: [ hosts.noConfig1 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'example-no-config-1'))).to.be.ok;
      });
    });

    it('caches remote http host repositories', function() {
      var ws = {
        client: {
          config: { "https://github.com/example/no-config-1.git": true }
        },
        hosts: [ hosts.noConfig1 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'example-no-config-1'))).to.be.ok;
      });
    });

  });

  describe('client configurations', function() {
    describe('simple configuration', function() {
      it('installs assets from hosts', function() {
        var ws = {
          client: {
            config: {
              "./repos/no-config-1": true,
              "./repos/no-config-2": true
            }
          },
          hosts: [ hosts.noConfig1, hosts.noConfig2 ]
        };
        workspace.setup(ws);

        return parachute.install().then(function() {
          var host1Items = _.keys(hosts.noConfig1.contents);
          var host2Items = _.keys(hosts.noConfig2.contents);
          _.union(host1Items, host2Items).forEach(function(item) {
            expect(fs.existsSync(path.resolve(item))).to.be.ok;
          });
        });
      });

      it('continues installation using an existing cache', function() {
        var ws = {
          client: {
            config: { "./repos/no-config-1": true }
          },
          hosts: [ hosts.noConfig1 ]
        };
        workspace.setup(ws);

        var mngr = new managerStub(ws.client.config);
        return mngr.cacheDependencies()
          .then(parachute.install)
          .then(function() {
            _.keys(hosts.noConfig1.contents).forEach(function(item) {
              expect(fs.existsSync(path.resolve(item))).to.be.ok;
            });
          });
      });
    });
  });
});
