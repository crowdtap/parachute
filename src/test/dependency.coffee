Dependency = require('../lib/core/dependency')
fs         = require('fs')
expect     = require('expect.js')
rimraf     = require('rimraf')

describe 'Dependency', ->
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
      dependency = new Dependency(remoteDependency)
      expect(dependency.src).to.eql(remoteDependency)
      done()

    it 'sets the name of the dependency', (done) ->
      dependency = new Dependency(remoteDependency)
      expect(dependency.name).to.eql('bar-baz')
      done()

    it 'sets the dependency cache directory', (done) ->
      dependency = new Dependency(remoteDependency)
      expect(dependency.cacheDir).to.eql("#{process.env['HOME']}/.parachute/bar-baz")
      done()

    it 'sets the dependency destination directory', (done) ->
      dependencyWithoutDirectory = new Dependency(remoteDependency)
      dependencyWithDirectory    = new Dependency(remoteDependency, root: 'css')
      expect(dependencyWithoutDirectory.root).to.eql(process.cwd())
      expect(dependencyWithDirectory.root).to.eql('css')
      done()

    it 'sets whether the dependency source is remote', (done) ->
      dependencyRemoteSsh  = new Dependency(remoteDependency)
      dependencyRemoteHttp = new Dependency('http://github.com/foo/bar')
      dependencyLocal      = new Dependency('path/to/repo')
      expect(dependencyRemoteSsh.remote).to.be(true)
      expect(dependencyRemoteHttp.remote).to.be(true)
      expect(dependencyLocal.remote).to.be(false)
      done()

  describe '#cache', ->
    it 'emits a cached event', (done) ->
      dependency = new Dependency('../repos/without_json')
      dependency.on 'error', (err) -> throw err
      dependency.on 'cached', (status) ->
        expect(status).to.be(0)
        done()
      dependency.cache()

    it 'clones the dependency source into the cache directory', (done) ->
      dependency = new Dependency('../repos/without_json')
      expect(fs.existsSync("#{process.env['HOME']}/.parachute/repos-without_json")).to.be(false)
      dependency.cache (status) ->
        expect(fs.existsSync("#{process.env['HOME']}/.parachute/repos-without_json")).to.be(true)
        done()

  describe '#isCached', ->
    it 'determines if the Dependency has been cached', (done) ->
      dependency = new Dependency('../repos/without_json')
      expect(dependency.isCached()).to.be(false)
      dependency.cache (status) ->
        expect(dependency.isCached()).to.be(true)
        rimraf dependency.cacheDir, (err) ->
          expect(dependency.isCached()).to.be(false)
          done()

  describe '#copy', ->
    it 'returns an error if dependency is not cached', (done) ->
      dependency = new Dependency('../repos/without_json')
      dependency.on 'error', (err) ->
        expect(err.message).to.eql('dependency is not cached')
        done()
      dependency.copy()

    it 'returns an error if dependency cache is dirty', (done) ->
      dependency = new Dependency('../repos/without_json')
      dependency.cache ->
        dependency.on 'error', (err) ->
          expect(err.message).to.eql('dependency cache is dirty')
          done()
        fs.unlinkSync "#{process.env['HOME']}/.parachute/repos-without_json/should-copy.txt"
        dependency.copy()

    it 'emits a copied event', (done) ->
      dependency = new Dependency('../repos/without_json')
      dependency.cache (status) ->
        dependency
          .on 'copied', (status) ->
            expect(status).to.be(0)
            done()
          .on 'error', (err) -> throw err
        dependency.copy()

    it 'does not copy ignored files from cache', (done) ->
      dependency = new Dependency('../repos/without_json')
      dependency.on 'error', (err) -> throw err
      dependency.cache ->
        dependency.copy ->
          expect(fs.existsSync("#{process.cwd()}/.git")).to.be(false)
          done()

    it 'allows a set of variable interpolation within assets.json', (done) ->
      dependency = new Dependency('../repos/with_variables')
      dependency.on 'error', (err) -> throw err
      dependency.cache ->
        dependency.copy ->
          expect(fs.existsSync("css/install_test/core.css")).to.be(true)
          done()

    describe 'source assets.json components option', ->
      it 'copies all cache contents if no source assets.json exists', (done) ->
        dependency = new Dependency('../repos/without_json')
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('should-copy.txt')).to.be(true)
            expect(fs.existsSync('css/core.css')).to.be(true)
            done()

      it 'copies cache contents according to assets.json when present', (done) ->
        dependency = new Dependency('../repos/with_json')
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('should-not-copy.txt')).to.be(false)
            expect(fs.existsSync('css/core.css')).to.be(false)
            expect(fs.existsSync('css/shared/core.css')).to.be(true)
            done()

    describe 'local assets.json files option', ->
      it 'copies filenames indicated in files option', (done) ->
        dependency = new Dependency('../repos/without_json', files: ['css/core.css'])
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('core.css')).to.be(true)
            expect(fs.existsSync('should-copy.txt')).to.be(false)
            done()

      it 'copies file objects indicated in files option', (done) ->
        files = [
          {
            src:  'css/core.css'
            dest: 'css/shared/core.css'
          }
        ]
        dependency = new Dependency('../repos/without_json', files: files)
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('css/shared/core.css')).to.be(true)
            expect(fs.existsSync('should-copy.txt')).to.be(false)
            done()

  describe '#hasPostScripts', ->
    it 'returns false if cached repo has no post_scripts folder', (done) ->
      dependency = new Dependency('../repos/without_json')
      dependency.cache ->
        expect(dependency.hasPostScripts()).to.be(false)
        done()

    it 'returns true if cached repo has post_scripts folder', (done) ->
      dependency = new Dependency('../repos/with_post_scripts')
      dependency.cache ->
        expect(dependency.hasPostScripts()).to.be(true)
        done()

    it 'emits an error if repo is not cached', (done) ->
      dependency = new Dependency('../repos/with_post_scripts')
      dependency.on 'error', (err) ->
        expect(err.message).to.eql('dependency is not cached')
        done()
      dependency.hasPostScripts()

  describe '#runPostScripts', ->
    it 'emits a post_scripts_complete event', (done) ->
      dependency = new Dependency('../repos/with_post_scripts')
      dependency.on 'error', (err) -> throw err
      dependency.cache ->
        dependency.copy ->
          dependency.on 'post_scripts_complete', ->
            done()
          dependency.runPostScripts()

    it 'emits an error if dependency is not cached', (done) ->
      dependency = new Dependency('../repos/with_post_scripts')
      dependency.on 'error', (err) ->
        expect(err.message).to.eql('dependency is not cached')
        done()
      dependency.runPostScripts()

    it 'runs all scripts within the post_scripts folder', (done) ->
      dependency = new Dependency('../repos/with_post_scripts')
      dependency.on 'error', (err) -> throw err
      dependency.cache ->
        dependency.copy ->
          dependency.on 'post_scripts_complete', ->
            expect(fs.existsSync('post_script_1.txt')).to.be(true)
            expect(fs.existsSync('post_script_2.txt')).to.be(true)
            done()
          dependency.runPostScripts()
