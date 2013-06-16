expect  = require('expect.js')
fs      = require('fs')
install = require('../lib/commands/install')
rimraf  = require('rimraf')
path    = require('path')

describe 'install', ->
  cwd     = process.cwd()
  testDir = "#{__dirname}/install_test"

  process.env['HOME'] = testDir

  noLocalnoSourceJson =
    src: "../repos/without_json/"
  yaLocalnoSourceJson =
    src: "../repos/without_json/"
    root: "some_folder/"
  noLocalyaSourceJson =
    src: "../repos/with_json/"
  yaLocalyaSourceJson =
    src: "../repos/with_json/"
    root: "some_folder/"
  withPostScript =
    src: "../repos/with_post_scripts/"

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

  it 'has a line function', (done) ->
    expect(!!install.line).to.be(true)
    done()

  describe 'events', ->
    it 'emits an end event', (done) ->
      install([noLocalnoSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(status).to.be(0)
          done()

    it 'emits data events', (done) ->
      install([noLocalnoSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'data', (data) ->
          expect(data).to.be.ok()
        .on 'end', (status) ->
          expect(status).to.be(0)
          done()

  describe 'without source assets.json', ->
    it 'saves dependencies into current working directory without root', (done) ->
      install([noLocalnoSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('should-copy.txt')).to.be(true)
          expect(fs.existsSync('css/core.css')).to.be(true)
          expect(fs.existsSync('.git')).to.be(false)
          done()

    it 'saves dependencies into root', (done) ->
      install([yaLocalnoSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('some_folder/should-copy.txt')).to.be(true)
          expect(fs.existsSync('some_folder/css/core.css')).to.be(true)
          expect(fs.existsSync('some_folder/.git')).to.be(false)
          done()

  describe 'with source json files option', ->
    it 'saves specified components in current working directory without root', (done) ->
      install([noLocalyaSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('css/shared/core.css')).to.be(true)
          expect(fs.existsSync('should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('assets.json')).to.be(false)
          expect(fs.existsSync('.git')).to.be(false)
          done()

    it 'saves specified components into root', (done) ->
      install([yaLocalyaSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('some_folder/css/shared/core.css')).to.be(true)
          expect(fs.existsSync('some_folder/should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('some_folder/assets.json')).to.be(false)
          expect(fs.existsSync('some_folder/.git')).to.be(false)
          done()

  describe 'with local files option', ->
    it 'saves specified components listed as strings', (done) ->
      json = noLocalyaSourceJson
      json.files = ['css/core.css']
      install([json])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('core.css')).to.be(true)
          expect(fs.existsSync('should-not-copy.txt')).to.be(false)
          done()

    it 'saves specified components listed as objects', (done) ->
      json = noLocalyaSourceJson
      json.files = [ src: 'css/core.css', dest: 'css/shared/']
      install([json])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('css/shared/core.css')).to.be(true)
          expect(fs.existsSync('css/shared/should-not-copy.txt')).to.be(false)
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
