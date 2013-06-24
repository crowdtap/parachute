{ EventEmitter } = require('events')
Manager          = require('../lib/core/manager')
Dependency       = require('../lib/core/dependency')
fs               = require('fs')
expect           = require('expect.js')
rimraf           = require('rimraf')
sinon            = require('sinon')

describe 'Manager', ->
  cwd     = process.cwd()
  testDir = "#{__dirname}/install_test"
  config  =
    dependencies: [
      {
        src: 'git@foo.com:bar/baz.git'
      },
      {
        src: 'git@bar.com:baz/foo.git'
      }
    ]

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

    @manager = new Manager(config.dependencies)

  after (done) ->
    process.chdir cwd
    clean(done)

  describe 'instance variables', ->
    it 'sets the dependencies on config', (done) ->
      expect(@manager.config.dependencies).to.eql(config.dependencies)
      done()

    it 'creates a dependencies variable of Dependency objects', (done) ->
      expect(@manager.dependencies).to.have.length(2)
      for _, i in @manager.dependencies
        expect(@manager.dependencies[i]).to.be.a(Dependency)
        expect(@manager.dependencies[i].src).to.be(config.dependencies[i].src)
      done()

  describe '#resolve', ->
    it 'emits a resolved event', (done) ->
      sinon.stub @manager.dependencies[0], 'cache', (cb) -> cb?()
      sinon.stub @manager.dependencies[1], 'cache', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .on 'resolved', (status) ->
          expect(status).to.be(0)
          done()
        .resolve()

    it 'caches dependencies', (done) ->
      sinon.stub @manager.dependencies[0], 'isCached', -> false
      sinon.stub @manager.dependencies[1], 'isCached', -> false
      stub1 = sinon.stub @manager.dependencies[0], 'cache', (cb) -> cb?()
      stub2 = sinon.stub @manager.dependencies[1], 'cache', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .resolve()

      expect(stub1.calledOnce).to.be(true)
      expect(stub2.calledOnce).to.be(true)
      done()

    it 'updates already cached dependencies', (done) ->
      manager = new Manager(config.dependencies, update: true)
      sinon.stub manager.dependencies[0], 'isCached', -> true
      sinon.stub manager.dependencies[1], 'isCached', -> true
      stubCache1 = sinon.stub manager.dependencies[0], 'cache', (cb) -> cb?()
      stubCache2 = sinon.stub manager.dependencies[1], 'cache', (cb) -> cb?()
      stubUpdate1 = sinon.stub manager.dependencies[0], 'update', (cb) -> cb?()
      stubUpdate2 = sinon.stub manager.dependencies[1], 'update', (cb) -> cb?()

      manager
        .on 'error', (err) ->
          throw err
        .resolve()

      expect(stubCache1.calledOnce).to.be(false)
      expect(stubCache2.calledOnce).to.be(false)
      expect(stubUpdate1.calledOnce).to.be(true)
      expect(stubUpdate2.calledOnce).to.be(true)
      done()

    it 'runs resolve scripts', (done) ->
      resolvedCount = 0
      preresolve    = false
      postresolve   = false

      scripts =
        preresolve:  'foo'
        postresolve: 'bar'
      manager = new Manager(config.dependencies, scripts: scripts)

      cacheFn = (cb) ->
        resolvedCount++
        cb?()

      sinon.stub manager.dependencies[0], 'isCached', -> false
      sinon.stub manager.dependencies[1], 'isCached', -> false
      sinon.stub manager.dependencies[0], 'cache', cacheFn
      sinon.stub manager.dependencies[1], 'cache', cacheFn

      runScriptStub = sinon.stub manager, 'runScript', (name) ->
        preresolve  = true if resolvedCount == 0 && name == 'preresolve'
        postresolve = true if resolvedCount == 2 && name == 'postresolve'

      manager
        .on 'error', (err) ->
          throw err
        .on 'resolved', ->
          # XXX There is a slight delay between catching the "resolve"
          # event here, and when @runScript is called
          setTimeout ->
            expect(runScriptStub.calledWith('preresolve')).to.be(true)
            expect(runScriptStub.calledWith('postresolve')).to.be(true)
            expect(preresolve).to.be(true)
            expect(postresolve).to.be(true)
            done()
          , 20
        .resolve()

  describe '#install', ->
    it 'emits an installed event', (done) ->
      for dependency in @manager.dependencies
        sinon.stub dependency, 'copy', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .on 'installed', (status) ->
          expect(status).to.be(0)
          done()
        .install()

    it 'copies dependencies', (done) ->
      stub1 = sinon.stub @manager.dependencies[0], 'copy', (cb) -> cb?()
      stub2 = sinon.stub @manager.dependencies[1], 'copy', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .install()

      expect(stub1.calledOnce).to.be(true)
      expect(stub2.calledOnce).to.be(true)
      done()

    it 'runs install scripts', (done) ->
      installCount = 0
      preinstall   = false
      postinstall  = false

      scripts =
        preinstall:  'foo'
        postinstall: 'bar'
      manager = new Manager(config.dependencies, scripts: scripts)

      copyFn = (cb) ->
        installCount++
        cb?()

      sinon.stub manager.dependencies[0], 'copy', copyFn
      sinon.stub manager.dependencies[1], 'copy', copyFn

      runScriptStub = sinon.stub manager, 'runScript', (name) ->
        preinstall  = true if installCount == 0 && name == 'preinstall'
        postinstall = true if installCount == 2 && name == 'postinstall'

      manager
        .on 'error', (err) ->
          throw err
        .on 'installed', ->
          # XXX There is a slight delay between catching the "installed"
          # event here, and when @runScript is called
          setTimeout ->
            expect(runScriptStub.calledWith('preinstall')).to.be(true)
            expect(runScriptStub.calledWith('postinstall')).to.be(true)
            expect(preinstall).to.be(true)
            expect(postinstall).to.be(true)
            done()
          , 20
        .install()

  describe '#update', ->
    it 'emits an updated event', (done) ->
      for dependency in @manager.dependencies
        sinon.stub dependency, 'update', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .on 'updated', (status) ->
          expect(status).to.be(0)
          done()
        .update()

    it 'updates dependencies', (done) ->
      stub1 = sinon.stub @manager.dependencies[0], 'update', (cb) -> cb?()
      stub2 = sinon.stub @manager.dependencies[1], 'update', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .update()

      expect(stub1.calledOnce).to.be(true)
      expect(stub2.calledOnce).to.be(true)
      done()

  describe '#runScript', ->
    it 'executes the script name', (done) ->
      manager = new Manager(config.dependencies, scripts: { foo: "pwd" })
      manager
        .on 'error', (err) ->
          throw err
        .on 'data', (data) ->
          expect(data.toString()).to.contain(process.env.HOME)
          done()
        .runScript('foo')
