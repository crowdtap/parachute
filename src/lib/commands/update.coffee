{ EventEmitter } = require('events')
Asset            = require('../core/asset')
config           = require('../core/config')

module.exports = (dependencies) ->
  emitter = new EventEmitter

  dependencies or= config.dependencies

  count = 0
  tick  = -> emitter.emit('end', 0) if ++count == dependencies.length

  for dependency in dependencies
    asset = new Asset(dependency.source, dependency.target)

    asset.on 'data',  emitter.emit.bind(emitter, 'data')
    asset.on 'error', emitter.emit.bind(emitter, 'error')

    asset.update(tick)

  return emitter
