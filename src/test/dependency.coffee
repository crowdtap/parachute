Dependency = require('../lib/core/dependency')
fs         = require('fs')
expect     = require('expect.js')
rimraf     = require('rimraf')
timekeeper = require('timekeeper')

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

    it 'allows a set of variable interpolation within parachute.json', (done) ->
      dependency = new Dependency('../repos/with_variables')
      dependency.on 'error', (err) -> throw err
      dependency.cache ->
        dependency.copy ->
          expect(fs.existsSync("css/install_test/core.css")).to.be(true)
          done()

    it 'allows a start of the year date variable interpolation within parachute.json', (done) ->
      dependency = new Dependency('../repos/with_variables')
      dependency.on 'error', (err) -> throw err
      timekeeper.travel(new Date(2013, 0, 1))
      dependency.cache ->
        dependency.copy ->
          expect(fs.existsSync("css/colors-2013-01-01.css")).to.be(true)
          expect(fs.existsSync("css/fonts-2013-01-01.css")).to.be(true)
          done()

    it 'allows an end of the year date variable interpolation within parachute.json', (done) ->
      dependency = new Dependency('../repos/with_variables')
      dependency.on 'error', (err) -> throw err
      timekeeper.travel(new Date(2013, 11, 31))
      dependency.cache ->
        dependency.copy ->
          expect(fs.existsSync("css/colors-2013-12-31.css")).to.be(true)
          expect(fs.existsSync("css/fonts-2013-12-31.css")).to.be(true)
          done()

    describe 'source parachute.json components option', ->
      it 'copies all cache contents if no source parachute.json exists', (done) ->
        dependency = new Dependency('../repos/without_json')
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('should-copy.txt')).to.be(true)
            expect(fs.existsSync('css/core.css')).to.be(true)
            done()

      it 'copies cache contents according to parachute.json when present', (done) ->
        dependency = new Dependency('../repos/with_json')
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('should-not-copy.txt')).to.be(false)
            expect(fs.existsSync('css/core.css')).to.be(false)
            expect(fs.existsSync('css/shared/core.css')).to.be(true)
            done()

    describe 'local parachute.json components option', ->
      it 'copies filenames indicated in components option', (done) ->
        dependency = new Dependency('../repos/without_json', components: ['css/core.css'])
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('core.css')).to.be(true)
            expect(fs.existsSync('should-copy.txt')).to.be(false)
            done()

      it 'copies file objects indicated in components option', (done) ->
        components = [
          {
            src:  'css/core.css'
            dest: 'css/shared/core.css'
          }
        ]
        dependency = new Dependency('../repos/without_json', components: components)
        dependency.on 'error', (err) -> throw err
        dependency.cache ->
          dependency.copy ->
            expect(fs.existsSync('css/shared/core.css')).to.be(true)
            expect(fs.existsSync('should-copy.txt')).to.be(false)
            done()
