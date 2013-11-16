rewire     = require('rewire')
gitWrapper = rewire('../lib/util/git-wrapper')

fs     = require('fs')
expect = require('expect.js')
sinon  = require('sinon')

describe 'git-wrapper', ->

  describe 'git process', ->
    beforeEach (done) ->
      @spawnStub = sinon.stub { spawn: -> }, 'spawn', (cmd, args, opts) ->
        cmd: cmd
        on: ->
        stderr:
          on: ->

      gitWrapper.__set__(spawn: @spawnStub)
      done()

    it 'spawns a git process with arguments', (done) ->
      gitArgs = ['clone', 'foo', 'bar']
      gitWrapper(gitArgs)

      expect(@spawnStub.calledWith('git', gitArgs)).to.be(true)
      done()

    it 'spawns a git process with arguments', (done) ->
      gitArgs = ['clone', 'foo', 'bar']
      gitOptions = { cwd: 'some/directory' }
      gitWrapper(gitArgs, gitOptions)

      expect(@spawnStub.calledWith('git', gitArgs, gitOptions)).to.be(true)
      done()

    it 'defaults options cwd to process.cwd', (done) ->
      gitArgs = ['clone', 'foo', 'bar']
      gitWrapper(gitArgs)

      expect(@spawnStub.calledWith('git', gitArgs, cwd: process.cwd())).to.be(true)
      done()

    it 'returns the git child process', (done) ->
      gitArgs     = ['clone', 'foo', 'bar']
      expectedObj = JSON.stringify @spawnStub('git')
      actualObj   = JSON.stringify gitWrapper(gitArgs)
      expect(actualObj).to.eql(expectedObj)
      done()

  describe 'events', ->
    beforeEach (done) ->
      gitWrapper.__set__
        console: { log: (msg) -> return msg }

      done()

    it 'displays stderr output', (done) ->
      @spawnStub = sinon.stub { spawn: -> }, 'spawn', (cmd, args, opts) ->
        on: ->
        stderr:
          on: (event, callback) ->
            expect(event).to.eql('data')
            expect(callback?('someErrorMsg')).to.eql("\nsomeErrorMsg")
            done()

      gitWrapper.__set__(spawn: @spawnStub)
      gitWrapper(['clone', 'foo', 'bar'])

    it 'does not display stderr output if verbose option is false', (done) ->
      stdErrOnStub = sinon.stub()
      @spawnStub = sinon.stub { spawn: -> }, 'spawn', (cmd, args, opts) ->
        on: ->
        stderr:
          on: stdErrOnStub

      gitWrapper.__set__(spawn: @spawnStub)
      gitWrapper(['clone', 'foo', 'bar'], verbose: false)
      expect(stdErrOnStub.called).to.be(false)
      done()

    it 'displays git exit code 128', (done) ->
      @spawnStub = sinon.stub { spawn: -> }, 'spawn', (cmd, args, opts) ->
        on: (event, callback) ->
          expect(event).to.eql('exit')
          expect(callback?(128)).to.eql("git did not exit cleanly!")
          done()
        stderr:
          on: ->

      gitWrapper.__set__(spawn: @spawnStub)
      gitWrapper(['clone', 'foo', 'bar'])
