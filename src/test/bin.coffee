expect = require('expect.js')
fs     = require('fs')
rimraf = require('rimraf')
spawn  = require('child_process').spawn

describe 'parachute', ->
  binPath = "#{ __dirname}/../bin/parachute"
  testDir = "#{__dirname}/install_test"

  clean = (done) ->
    rimraf testDir, (err) ->
      throw new Error('Unable to remove install directory') if err
      done()

  beforeEach (done) ->
    clean ->
      fs.mkdirSync testDir
      done()

  after(clean)

  it 'exits with status code 0 if there were no errors', (done) ->
    cp = spawn('node', [binPath], cwd: testDir)

    cp.on 'exit', (status) =>
      expect(status).to.eql(0)
      done()

  #it 'exits with status code 1 if there were errors', (done) ->
    #cp = spawn('node', [binPath], cwd: testDir)

    #cp.on 'exit', (status) =>
      #expect(status).to.eql(1)
      #done()
