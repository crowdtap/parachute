expect  = require('expect.js')
fs      = require('fs')
install = require('../lib/commands/install')
rimraf  = require('rimraf')
path    = require('path')

describe 'install', ->
  cwd     = process.cwd()
  testDir = "#{__dirname}/install_test"

  noLocalnoSourceJson =
    source: "../repos/without_json"
  yaLocalnoSourceJson =
    source: "../repos/without_json"
    target: "some_folder"
  noLocalyaSourceJson =
    source: "../repos/with_json"
  yaLocalyaSourceJson =
    source: "../repos/with_json"
    target: "some_folder"
  withPostScript =
    source: "../repos/with_post_scripts"

  clean = (done) ->
    rimraf testDir, (err) ->
      throw new Error('Unable to remove install directory') if err
      done?()

  beforeEach (done) ->
    process.chdir cwd
    clean ->
      fs.mkdir testDir, (err) ->
        throw err if err
        process.chdir testDir
        done?()

  after (done) ->
    process.chdir cwd
    clean(done)

  it 'emits an end event', (done) ->
    install([noLocalnoSourceJson])
      .on 'error', (err) ->
        throw err
      .on 'end', (status) ->
        expect(status).to.be(0)
        done()

  describe 'without source json', ->
    it 'saves dependencies into current working directory without local target', (done) ->
      install([noLocalnoSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('should-copy.txt')).to.be(true)
          expect(fs.existsSync('css/core.css')).to.be(true)
          expect(fs.existsSync('.git')).to.be(false)
          done()

    it 'saves dependencies into local target', (done) ->
      install([yaLocalnoSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('some_folder/should-copy.txt')).to.be(true)
          expect(fs.existsSync('some_folder/css/core.css')).to.be(true)
          expect(fs.existsSync('some_folder/.git')).to.be(false)
          done()

  describe 'with source json', ->
    it 'saves specified components in current working directory without local target', (done) ->
      install([noLocalyaSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('css/shared/core.css')).to.be(true)
          expect(fs.existsSync('should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('assets.json')).to.be(false)
          expect(fs.existsSync('.git')).to.be(false)
          done()

    it 'saves specified components into local target', (done) ->
      install([yaLocalyaSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('some_folder/css/shared/core.css')).to.be(true)
          expect(fs.existsSync('some_folder/should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('some_folder/assets.json')).to.be(false)
          expect(fs.existsSync('some_folder/.git')).to.be(false)
          done()

  describe 'post scripts', ->
    it 'does not copy post_scripts directory', (done) ->
      install([withPostScript])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('post_scripts')).to.be(false)
          done()

    it 'runs post scripts after install', (done) ->
      expect(fs.existsSync('post_script_1.txt')).to.be(false)
      expect(fs.existsSync('post_script_2.txt')).to.be(false)
      install([withPostScript])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('post_script_1.txt')).to.be(true)
          expect(fs.existsSync('post_script_2.txt')).to.be(true)
          done()
