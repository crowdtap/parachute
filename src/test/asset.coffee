Asset  = require('../lib/core/asset')
fs     = require('fs')
expect = require('expect.js')
rimraf = require('rimraf')

describe 'Asset', ->
  cwd              = process.cwd()
  remoteDependency = 'git@foo.com:bar/baz.git'
  testDir          = "#{__dirname}/install_test"

  process.env['HOME'] = testDir

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
      expect(asset.cacheDir).to.eql("#{process.env['HOME']}/.parachute/bar-baz")
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
    it 'emits a cached event', (done) ->
      asset = new Asset('../repos/without_json')
      asset.on 'error', (err) -> throw err
      asset.on 'cached', (status) ->
        expect(status).to.be(0)
        done()
      asset.cache()

    it 'clones the asset source into the cache directory', (done) ->
      asset = new Asset('../repos/without_json')
      expect(fs.existsSync("#{process.env['HOME']}/.parachute/repos-without_json")).to.be(false)
      asset.cache (status) ->
        expect(fs.existsSync("#{process.env['HOME']}/.parachute/repos-without_json")).to.be(true)
        done()

  describe '#isCached', ->
    it 'determines if the Asset has been cached', (done) ->
      asset = new Asset('../repos/without_json')
      expect(asset.isCached()).to.be(false)
      asset.cache (status) ->
        expect(asset.isCached()).to.be(true)
        rimraf asset.cacheDir, (err) ->
          expect(asset.isCached()).to.be(false)
          done()

  describe '#copy', ->
    it 'returns an error if asset is not cached', (done) ->
      asset = new Asset('../repos/without_json')
      asset.on 'error', (err) ->
        expect(err.message).to.eql('asset is not cached')
        done()
      asset.copy()

    it 'returns an error if asset cache is dirty', (done) ->
      asset = new Asset('../repos/without_json')
      asset.cache ->
        asset.on 'error', (err) ->
          expect(err.message).to.eql('asset cache is dirty')
          done()
        fs.unlinkSync "#{process.env['HOME']}/.parachute/repos-without_json/should-copy.txt"
        asset.copy()

    it 'emits a copied event', (done) ->
      asset = new Asset('../repos/without_json')
      asset.cache (status) ->
        asset
          .on 'copied', (status) ->
            expect(status).to.be(0)
            done()
          .on 'error', (err) -> throw err
        asset.copy()

    it 'copies all cache contents if no source assets.json exists', (done) ->
      asset = new Asset('../repos/without_json')
      asset.on 'error', (err) -> throw err
      asset.cache ->
        asset.copy ->
          expect(fs.existsSync('should-copy.txt')).to.be(true)
          expect(fs.existsSync('css/core.css')).to.be(true)
          done()

    it 'xxx copies cache contents according to assets.json when present', (done) ->
      asset = new Asset('../repos/with_json')
      asset.on 'error', (err) -> throw err
      asset.cache ->
        asset.copy ->
          expect(fs.existsSync('should-not-copy.txt')).to.be(false)
          expect(fs.existsSync('css/core.css')).to.be(false)
          expect(fs.existsSync('css/shared/core.css')).to.be(true)
          done()

    it 'does not copy ignored files from cache', (done) ->
      asset = new Asset('../repos/without_json')
      asset.on 'error', (err) -> throw err
      asset.cache ->
        asset.copy ->
          expect(fs.existsSync("#{process.cwd()}/.git")).to.be(false)
          done()

    it 'allows a set of variable interpolation within assets.json', (done) ->
      asset = new Asset('../repos/with_variables')
      asset.on 'error', (err) -> throw err
      asset.cache ->
        asset.copy ->
          expect(fs.existsSync("css/install_test/core.css")).to.be(true)
          done()

  describe '#hasPostScripts', ->
    it 'returns false if cached repo has no post_scripts folder', (done) ->
      asset = new Asset('../repos/without_json')
      asset.cache ->
        expect(asset.hasPostScripts()).to.be(false)
        done()

    it 'returns true if cached repo has post_scripts folder', (done) ->
      asset = new Asset('../repos/with_post_scripts')
      asset.cache ->
        expect(asset.hasPostScripts()).to.be(true)
        done()

    it 'emits an error if repo is not cached', (done) ->
      asset = new Asset('../repos/with_post_scripts')
      asset.on 'error', (err) ->
        expect(err.message).to.eql('asset is not cached')
        done()
      asset.hasPostScripts()

  describe '#runPostScripts', ->
    it 'emits a post_scripts_complete event', (done) ->
      asset = new Asset('../repos/with_post_scripts')
      asset.on 'error', (err) -> throw err
      asset.cache ->
        asset.copy ->
          asset.on 'post_scripts_complete', ->
            done()
          asset.runPostScripts()

    it 'emits an error if asset is not cached', (done) ->
      asset = new Asset('../repos/with_post_scripts')
      asset.on 'error', (err) ->
        expect(err.message).to.eql('asset is not cached')
        done()
      asset.runPostScripts()

    it 'runs all scripts within the post_scripts folder', (done) ->
      asset = new Asset('../repos/with_post_scripts')
      asset.on 'error', (err) -> throw err
      asset.cache ->
        asset.copy ->
          asset.on 'post_scripts_complete', ->
            expect(fs.existsSync('post_script_1.txt')).to.be(true)
            expect(fs.existsSync('post_script_2.txt')).to.be(true)
            done()
          asset.runPostScripts()
