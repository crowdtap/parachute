{ EventEmitter } = require('events')
Asset            = require('../core/asset')
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

  for dependency in dependencies
    asset = new Asset(dependency.source, dependency.target)

    asset.on 'data',  emitter.emit.bind(emitter, 'data')
    asset.on 'error', emitter.emit.bind(emitter, 'error')

    asset.update(tick)

  return emitter

module.exports.line = (argv) ->
  options = nopt(optionTypes, shorthand, argv)
  if options.help
    help('update')
  else
    module.exports(config.dependencies, options)
