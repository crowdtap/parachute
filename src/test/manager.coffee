{ EventEmitter } = require('events')
Manager          = require('../lib/core/manager')
Dependency       = require('../lib/core/dependency')
fs               = require('fs')
expect           = require('expect.js')
rimraf           = require('rimraf')
sinon            = require('sinon')

describe 'Dependency', ->
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
      @manager = new Manager(config.dependencies, update: true)
      sinon.stub @manager.dependencies[0], 'isCached', -> true
      sinon.stub @manager.dependencies[1], 'isCached', -> true
      stubCache1 = sinon.stub @manager.dependencies[0], 'cache', (cb) -> cb?()
      stubCache2 = sinon.stub @manager.dependencies[1], 'cache', (cb) -> cb?()
      stubUpdate1 = sinon.stub @manager.dependencies[0], 'update', (cb) -> cb?()
      stubUpdate2 = sinon.stub @manager.dependencies[1], 'update', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .resolve()

      expect(stubCache1.calledOnce).to.be(false)
      expect(stubCache2.calledOnce).to.be(false)
      expect(stubUpdate1.calledOnce).to.be(true)
      expect(stubUpdate2.calledOnce).to.be(true)
      done()

  describe '#install', ->
    it 'emits an installed event', (done) ->
      for dependency in @manager.dependencies
        sinon.stub dependency, 'copy', (cb) -> cb?()
        sinon.stub dependency, 'hasPostScripts', -> false

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
      for dependency in @manager.dependencies
        sinon.stub dependency, 'hasPostScripts', -> false

      @manager
        .on 'error', (err) ->
          throw err
        .install()

      expect(stub1.calledOnce).to.be(true)
      expect(stub2.calledOnce).to.be(true)
      done()

    it 'runs post scripts after copy', (done) ->
      sinon.stub @manager.dependencies[0], 'copy', (cb) -> cb?()
      sinon.stub @manager.dependencies[1], 'copy', (cb) -> cb?()
      stubHas1 = sinon.stub @manager.dependencies[0], 'hasPostScripts', -> true
      stubHas2 = sinon.stub @manager.dependencies[1], 'hasPostScripts', -> false
      stubRun1 = sinon.stub @manager.dependencies[0], 'runPostScripts', (cb) -> cb?()
      stubRun2 = sinon.stub @manager.dependencies[1], 'runPostScripts', (cb) -> cb?()

      @manager
        .on 'error', (err) ->
          throw err
        .install()

      expect(stubHas1.calledOnce).to.be(true)
      expect(stubHas2.calledOnce).to.be(true)
      expect(stubRun1.calledOnce).to.be(true)
      expect(stubRun2.calledOnce).to.be(false)
      done()

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
