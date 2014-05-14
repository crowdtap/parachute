var expect    = require('chai').expect;
var parachute = require('../lib');

describe('install', function() {
  it('should do something', function(done) {
    expect(parachute.install()).to.eql('hello world');
    done();
  });
});
