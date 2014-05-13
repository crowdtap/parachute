{ EventEmitter } = require('events')
nopt             = require('nopt')
template         = require('../util/template')

module.exports = (name) ->
  emitter = new EventEmitter

  templateName = if name? then "help-#{name}" else 'help'
  template(templateName).on('data', emitter.emit.bind(emitter, 'end'))

  emitter

module.exports.line = (argv) ->
  options = nopt(null, null, argv)
  module.exports(options.argv.remain.slice(1)[0])
