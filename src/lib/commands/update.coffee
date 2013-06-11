{ EventEmitter } = require('events')
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

  count = 0
  tick  = -> emitter.emit('end', 0) if ++count == dependencies.length

  for debObj in dependencies
    dependency = new Dependency(debObj.source, debObj.target)

    dependency.on 'data',  emitter.emit.bind(emitter, 'data')
    dependency.on 'error', emitter.emit.bind(emitter, 'error')

    dependency.update(tick)

  return emitter

module.exports.line = (argv) ->
  options = nopt(optionTypes, shorthand, argv)
  if options.help
    help('update')
  else
    module.exports(config.dependencies, options)
