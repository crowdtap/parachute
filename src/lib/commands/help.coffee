{ EventEmitter } = require('events')
template         = require('../util/template')

module.exports = ->
  emitter = new EventEmitter
  template('help').on('data', emitter.emit.bind(emitter, 'end'))
  emitter
