/* jshint expr:true */

var chai           = require('chai');
var chaiAsPromised = require('chai-as-promised');
var expect         = chai.expect;
chai.use(chaiAsPromised);

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


describe('#install', function() {
  var cwd          = process.cwd();
  var testDir      = __dirname + '/tmp';
  process.env.HOME = testDir;

  // Predefined host repos
  var noConfig1 = {
    name: 'no-config-1',
    contents: {
      'no-config-1-asset-1.txt': 'file',
      'no-config-1-asset-2.txt': 'file'
    }
  };
  var noConfig2 = {
    name: 'no-config-2',
    contents: {
      'no-config-2-asset-1.txt': 'file',
      'no-config-2-asset-2.txt': 'file'
    }
  };

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
        hosts: [ noConfig1 ]
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
        hosts: [ noConfig1 ]
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
        hosts: [ noConfig1 ]
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
          hosts: [ noConfig1, noConfig2 ]
        };
        workspace.setup(ws);

        return parachute.install().then(function() {
          expect(fs.existsSync('./no-config-1-asset-1.txt')).to.be.ok;
          expect(fs.existsSync('./no-config-1-asset-2.txt')).to.be.ok;
          expect(fs.existsSync('./no-config-2-asset-1.txt')).to.be.ok;
          expect(fs.existsSync('./no-config-2-asset-2.txt')).to.be.ok;
        });
      });
    });
  });
});
