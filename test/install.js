/* jshint expr:true */

var chai           = require('chai');
var chaiAsPromised = require('chai-as-promised');
var expect         = chai.expect;

var Q      = require('q');
var fs     = require('fs');
var ncp    = require('ncp');
var path   = require('path');
var rimraf = require('rimraf');
var rewire = require('rewire');

var gitStub = function(args) {
  if (args[0] === 'clone') {
    return Q.nfcall(ncp, args[1], args[2]);
  }
};

var parachute = rewire('../lib');
parachute.__set__('git', gitStub);

chai.use(chaiAsPromised);

describe('install', function() {
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

  describe('caches', function() {
    it('local host repositories', function() {
      var config = {
        "../repos/no-config-1": true
      };

      fs.writeFileSync('parachute.json', JSON.stringify(config));
      return parachute.install().then(function() {
        var cacheDir = path.join(process.env.HOME, './.parachute');
        expect(fs.existsSync(path.join(cacheDir, 'no-config-1'))).to.be.ok;
      });
    });
  });

  describe.skip('client configurations', function() {
    describe('simple configuration', function() {
      it('installs assets from hosts', function() {
        var config = {
          "../repos/no-config-1": true
        };

        fs.writeFileSync('parachute.json', JSON.stringify(config));
        return parachute.install().then(function() {
          expect(fs.existsSync('./no-config-1-asset-1.txt')).to.be.ok;
          expect(fs.existsSync('./no-config-1-asset-2.txt')).to.be.ok;
        });
      });
    });
  });
});
