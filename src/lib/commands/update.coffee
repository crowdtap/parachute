{ EventEmitter } = require('events')
Manager          = require('../core/manager')
Dependency       = require('../core/dependency')
config           = require('../core/config')
help             = require('../commands/help')
nopt             = require('nopt')

optionTypes =
  help:   Boolean

shorthand =
  h: ['--help']

module.exports = (dependencies, options) ->
  emitter = new EventEmitter
  manager = new Manager(dependencies, options)

  manager
    .on('error', emitter.emit.bind(emitter, 'error'))
    .on 'updated', ->
      emitter.emit('end', 0)
    .update()

  return emitter

module.exports.line = (argv) ->
  options = nopt(optionTypes, shorthand, argv)
  if options.help
    help('update')
  else
    module.exports(config.dependencies, options)
