/* jshint expr:true */

var chai           = require('chai');
var chaiAsPromised = require('chai-as-promised');
var expect         = chai.expect;
chai.use(chaiAsPromised);

var Q      = require('q');
var _      = require('lodash');
var fs     = require('fs');
var ncp    = require('ncp');
var path   = require('path');
var rimraf = require('rimraf');
var rewire = require('rewire');


var gitStub = function(args) {
  var cmd = args[0];
  if (cmd === 'clone') {
    var src = args[1];
    var dest = args[2];
    if (src.match(/git@|http/i)) {
      var repo = _.last(src.split('/'));
      if (repo.slice(-4) === '.git') repo = repo.slice(0,-4);
      src = path.join('../repos', repo);
    }
    return Q.nfcall(ncp, src, dest);
  }
};

var writeParachuteConfig = function(config) {
  return fs.writeFileSync('parachute.json', JSON.stringify(config));
};

var managerStub = rewire('../lib/Manager');
managerStub.__set__('git', gitStub);

var parachute = rewire('../lib');
parachute.__set__('Manager', managerStub);


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
      var config = { "../repos/no-config-1": true };
      writeParachuteConfig(config);

      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'no-config-1'))).to.be.ok;
      });
    });

    it('caches remote ssh host repositories', function() {
      var config = { "git@github.com:example/no-config-1.git": true };
      writeParachuteConfig(config);

      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'example-no-config-1'))).to.be.ok;
      });
    });

    it('caches remote http host repositories', function() {
      var config = { "https://github.com/example/no-config-1.git": true };
      writeParachuteConfig(config);

      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'example-no-config-1'))).to.be.ok;
      });
    });
  });

  describe('client configurations', function() {
    describe('simple configuration', function() {
      it('installs assets from hosts', function() {
        var config = {
          "../repos/no-config-1": true,
          "../repos/no-config-2": true
        };
        writeParachuteConfig(config);

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
