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

  describe 'without source parachute.json', ->
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

  describe 'with source json components option', ->
    it 'saves specified components in current working directory without root', (done) ->
      install([noLocalyaSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('css/shared/core.css')).to.be(true)
          expect(fs.existsSync('should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('parachute.json')).to.be(false)
          expect(fs.existsSync('.git')).to.be(false)
          done()

    it 'saves specified components into root', (done) ->
      install([yaLocalyaSourceJson])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('some_folder/css/shared/core.css')).to.be(true)
          expect(fs.existsSync('some_folder/should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('some_folder/parachute.json')).to.be(false)
          expect(fs.existsSync('some_folder/.git')).to.be(false)
          done()

  describe 'with local components option', ->
    it 'saves specified components listed as strings', (done) ->
      json = noLocalyaSourceJson
      json.components = ['css/core.css']
      install([json])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('core.css')).to.be(true)
          expect(fs.existsSync('should-not-copy.txt')).to.be(false)
          done()

    it 'saves specified components listed as objects', (done) ->
      json = noLocalyaSourceJson
      json.components = [ src: 'css/core.css', dest: 'css/shared/']
      install([json])
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          expect(fs.existsSync('css/shared/core.css')).to.be(true)
          expect(fs.existsSync('css/shared/should-not-copy.txt')).to.be(false)
          done()

  describe 'scripts', ->
    it 'runs install and resolve scripts', (done) ->
      scripts =
        preresolve:  'touch preresolve_script.txt'
        postresolve: 'touch postresolve_script.txt'
        preinstall:  'touch preinstall_script.txt'
        postinstall: 'touch postinstall_script.txt'

      expect(fs.existsSync('preresolve_script.txt')).to.be(false)
      expect(fs.existsSync('postresolve_script.txt')).to.be(false)
      expect(fs.existsSync('preinstall_script.txt')).to.be(false)
      expect(fs.existsSync('postinstall_script.txt')).to.be(false)
      install([noLocalnoSourceJson], scripts: scripts)
        .on 'error', (err) ->
          throw err
        .on 'end', (status) ->
          # XXX There is a slight delay between catching the "end"
          # event here, and when @runScript is called
          setTimeout ->
            expect(fs.existsSync('preresolve_script.txt')).to.be(true)
            expect(fs.existsSync('postresolve_script.txt')).to.be(true)
            expect(fs.existsSync('preinstall_script.txt')).to.be(true)
            expect(fs.existsSync('postinstall_script.txt')).to.be(true)
            done()
          , 20
