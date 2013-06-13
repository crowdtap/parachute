{ EventEmitter } = require('events')
Manager          = require('../core/manager')
Dependency       = require('../core/dependency')
config           = require('../core/config')
help             = require('../commands/help')
nopt             = require('nopt')

optionTypes =
  help:   Boolean
  update: Boolean

shorthand =
  h: ['--help']
  u: ['--update']

module.exports = (dependencies, options) ->
  emitter = new EventEmitter
  manager = new Manager(dependencies, options)

  manager
    .on('error', emitter.emit.bind(emitter, 'error'))
    .on('data',  emitter.emit.bind(emitter, 'data'))
    .on 'resolved', (status) ->
      @install()
    .on 'installed', (status) ->
      emitter.emit('end', 0)
    .resolve()

  return emitter

module.exports.line = (argv) ->
  options = nopt(optionTypes, shorthand, argv)
  if options.help
    help('install')
  else
    module.exports(config.dependencies, options)
