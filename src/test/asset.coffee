Asset  = require('../lib/core/asset')
fs     = require('fs')
expect = require('expect.js')
rimraf = require('rimraf')

describe 'Asset', ->
  remoteDependency = 'git@foo.com:bar/baz.git'

  describe 'instance variables', ->
    it 'sets the source URL', (done) ->
      asset = new Asset(remoteDependency)
      expect(asset.source).to.eql(remoteDependency)
      done()

    it 'sets the name of the asset', (done) ->
      asset = new Asset(remoteDependency)
      expect(asset.name).to.eql('bar-baz')
      done()

    it 'sets the asset cache directory', (done) ->
      asset = new Asset(remoteDependency)
      expect(asset.cacheDir).to.eql("#{process.cwd()}/.parachute/bar-baz")
      done()

    it 'sets the asset target directory', (done) ->
      assetWithoutDirectory = new Asset(remoteDependency)
      assetWithDirectory    = new Asset(remoteDependency, 'css')
      expect(assetWithoutDirectory.targetDir).to.eql(process.cwd())
      expect(assetWithDirectory.targetDir).to.eql('css')
      done()

    it 'sets whether the asset source is remote', (done) ->
      assetRemoteSsh  = new Asset(remoteDependency)
      assetRemoteHttp = new Asset('http://github.com/foo/bar')
      assetLocal      = new Asset('path/to/repo')
      expect(assetRemoteSsh.remote).to.be(true)
      expect(assetRemoteHttp.remote).to.be(true)
      expect(assetLocal.remote).to.be(false)
      done()

  describe '#cache', ->
    testDir = "#{__dirname}/install_test"

    clean = (done) ->
      rimraf testDir, (err) ->
        console.log err
        throw new Error('Unable to remove install directory') if err
        done() if done?()

    beforeEach (done) ->
      clean ->
        fs.mkdirSync testDir
        process.chdir testDir
        done() if done?()

    after ->
      process.chdir '../'
      clean()

    it 'emits a cached event', (done) ->
      asset = new Asset('../repos/without_json')
      asset.cache()
        .on 'error', (err) ->
          throw err
        .on 'cached', (status) ->
          expect(status).to.be(0)
          done()

    it 'clones the asset source into the cache directory', (done) ->
      asset = new Asset('../repos/without_json')
      expect(fs.existsSync('.parachute/repos-without_json')).to.be(false)
      asset.cache().on 'cached', (status) ->
        expect(fs.existsSync('.parachute/repos-without_json')).to.be(true)
        done()
