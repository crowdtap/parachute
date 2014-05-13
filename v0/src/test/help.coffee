{ EventEmitter } = require('events')
expect           = require('expect.js')
help             = require('../lib/commands/help')

describe 'help', ->
  it 'returns an emitter', ->
    expect(help() instanceof EventEmitter).to.be(true)

  it 'emits an end event', (done) ->
    help().on 'end', (data) ->
      expect(data).to.be.ok()
      done()

  it 'emits an end event with data string', (done) ->
    help().on 'end', (data) ->
      expect(data).to.be.a('string')
      done()
