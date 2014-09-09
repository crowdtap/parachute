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

var dependencyStub = rewire('../lib/Dependency');
dependencyStub.__set__('git', gitStub);

var managerStub = rewire('../lib/Manager');
managerStub.__set__('Dependency', dependencyStub);

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

  // TODO: Better testing of git actions
  describe('dependency treeish behavior', function() {
    it('checks out master by default', function() {
      var ws = {
        client: {
          config: {
            "./repos/no-config-1": true,
          }
        },
        hosts: [ hosts.noConfig1 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        expect(gitStub(null, ['_HEAD'])).to.eql('master');
      });
    });

    it('checks out treeish on local repo', function() {
      var ws = {
        client: {
          config: {
            "./repos/no-config-1#0b75bb5": true,
          }
        },
        hosts: [ hosts.noConfig1 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        expect(gitStub(null, ['_HEAD'])).to.eql('0b75bb5');
      });
    });

    it('checks out treeish on remote repo', function() {
      var ws = {
        client: {
          config: {
            "git@github.com:repos/no-config-1#0b75bb5": true,
          }
        },
        hosts: [ hosts.noConfig1 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        expect(gitStub(null, ['_HEAD'])).to.eql('origin/0b75bb5');
      });
    });
  });

  describe('simple client configurations', function() {
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
          expect(fs.existsSync(path.resolve(item))).to.eql(true, item + ' not delivered');
        });
      });
    });

    it('ignores certain files', function() {
      var ws = {
        client: {
          config: {
            "./repos/with-ignored-files": true,
          }
        },
        hosts: [ hosts.withIgnoredFiles ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var hostItems = _.keys(hosts.withIgnoredFiles.contents);
        var shouldIgnore = _.filter(hostItems, function(item) {
          return item.match(new RegExp(".git|.*.log$|^\\..*"));
        });
        var shouldDeliver = _.difference(hostItems, shouldIgnore, ['.parachute']);

        shouldIgnore.forEach(function(item) {
          item = path.resolve(item);
          expect(fs.existsSync(item)).to.eql(false, item + ' should have been ignored');
        });

        shouldDeliver.forEach(function(item) {
          item = path.resolve(item);
          expect(fs.existsSync(item)).to.eql(true, item + ' should have been delivered');
        });

        // Also check that client parachute.json was not stomped
        var clientParachute = JSON.parse(fs.readFileSync('./parachute.json'));
        expect(clientParachute).to.eql(ws.client.config);
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

  describe('basic client configuration options', function() {
    it('allows a root folder to be set', function() {
      var assetsRoot = 'shared/assets/';
      var ws = {
        client: {
          config: {
            "./repos/no-config-1": {
              root: assetsRoot,
              only: [
                { "flannel.png": "bar/" }
              ]
            },
            "./repos/no-config-2": {
              "root": assetsRoot
            }
          }
        },
        hosts: [ hosts.noConfig1, hosts.noConfig2 ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var host1Items = [ assetsRoot + 'bar/flannel.png' ];
        var host2Items = _.keys(hosts.noConfig2.contents).map(function(item) {
          return assetsRoot + item;
        });
        _.union(host1Items, host2Items).forEach(function(item) {
          expect(fs.existsSync(path.resolve(item))).to.eql(true, item + ' not delivered');
        });
      });
    });
  });

  describe('host configurations', function() {
    describe('only directive', function() {
      it('whitelists asset delivery to those specified', function() {
        var ws = {
          client: {
            config: {
              "./repos/only-array-config": true
            }
          },
          hosts: [ hosts.onlyArrayConfig ]
        };
        workspace.setup(ws);

        return parachute.install().then(function() {
          var expectedFiles = [
            'css/shared.css',
            'shared/williamsburg.png',
            'shared/brooklyn.png'
          ];
          var unexpectedFiles = [
            'css/not-shared.css',
             'javascripts'
          ];

          expectedFiles.forEach(function(item) {
            var errMsg = item + ' not delivered';
            expect(fs.existsSync(path.resolve(item))).to.eql(true, errMsg);
          });
          unexpectedFiles.forEach(function(item) {
            var errMsg = item + ' should not have been delivered';
            expect(fs.existsSync(path.resolve(item))).to.eql(false, errMsg);
          });
        });
      });
    });

    describe('except directive', function() {
      it('blacklists asset delivery to those specified', function() {
        var ws = {
          client: {
            config: {
              "./repos/except-array-config": true
            }
          },
          hosts: [ hosts.exceptArrayConfig ]
        };
        workspace.setup(ws);

        return parachute.install().then(function() {
          var expectedFiles = [
            'css/shared.css',
            'images/williamsburg.png',
            'images/brooklyn.png'
          ];
          var unexpectedFiles = [ 'css/not-shared.css', 'javascripts' ];
          expectedFiles.forEach(function(item) {
            var errMsg = item + ' not delivered';
            expect(fs.existsSync(path.resolve(item))).to.eql(true, errMsg);
          });
          unexpectedFiles.forEach(function(item) {
            var errMsg = item + ' should not have been delivered';
            expect(fs.existsSync(path.resolve(item))).to.eql(false, errMsg);
          });
        });
      });
    });
  });

  describe('asset groups', function() {
    it('allows for selecting groups of assets', function() {
      var ws = {
        client: {
          config: {
            "./repos/asset-groups-config": {
              "groups": [ 'webdriver', 'bootstrap', 'scripts' ]
            }
          }
        },
        hosts: [ hosts.assetGroupsConfig ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var expectedFiles = [
          'run_tests.sh',
          'testing/start',
          'testing/scripts/selenium.jar',
          'css/shared/bootstrap.less',
          'scripts/some_script.sh'
        ];
        var unexpectedFiles = [
          'images/bespoke.png',
          'images/gastropub.png',
          'javascripts/core.js'
        ];
        expectedFiles.forEach(function(item) {
          // TODO: Do this file exists and is file type check for all tests
          var errMissingMsg = item + ' not delivered';
          var errNotFileMsg = item + ' is not a file';
          expect(fs.existsSync(path.resolve(item))).to.eql(true, errMissingMsg);
          expect(fs.lstatSync(path.resolve(item)).isFile()).to.eql(true, errNotFileMsg);
        });
        unexpectedFiles.forEach(function(item) {
          var errMsg = item + ' should not have been delivered';
          expect(fs.existsSync(path.resolve(item))).to.eql(false, errMsg);
        });
      });
    });
  });

  describe('path combinations', function() {
    it('delivers assets with expected paths', function() {
      var ws = {
        client: {
          config: {
            "./repos/paths-combinations": true
          }
        },
        hosts: [ hosts.pathsCombinations ]
      };
      workspace.setup(ws);

      return parachute.install().then(function() {
        var expectedFiles = [
          'singleFile1.txt',
          'nested/file1.txt',
          'deliverAllDir/nestedFile1.txt',
          'deliverAllDir/nestedFile2.txt',
          'globbedFile1.txt',
          'subDir/globbedFile2.txt',
          'shared/fileToDir.txt',
          'renamedFile.txt',
          'shared/renamedUnderDir.txt',
          'shared/nestedRenamedFile.txt',
          'shared/nestedFileUnderDir.txt',
          'globbed/file1.txt',
          'globbed/file2.txt',
          'globbedStructure/foo1.txt',
          'globbedStructure/subDir/foo2.txt'
        ];
        expectedFiles.forEach(function(item) {
          var errMissingMsg = item + ' not delivered';
          var errNotFileMsg = item + ' is not a file';
          expect(fs.existsSync(path.resolve(item))).to.eql(true, errMissingMsg);
          expect(fs.lstatSync(path.resolve(item)).isFile()).to.eql(true, errNotFileMsg);
        });
      });
    });
  });
});
