expect = require('expect.js')
fs     = require('fs')
rimraf = require('rimraf')
spawn  = require('child_process').spawn

describe 'version', ->
  binPath = "#{ __dirname}/../bin/parachute"

  it 'prints the version', (done) ->
    pkg = require('../package.json')
    cp  = spawn('node', [binPath, '-v'])

    cp.stdout.on 'data', (data) =>
      expect(data.toString()).to.contain(pkg.version)
      done()
