{ EventEmitter } = require('events')
Asset            = require('../core/asset')
fs               = require('fs')
path             = require('path')
config           = require('../core/config')

module.exports = (dependencies) ->
  emitter = new EventEmitter
  emitter.emit.bind emitter, 'data'
  emitter.emit.bind emitter, 'error'

  dependencies or= config.dependencies

  count = 0
  tick  = -> emitter.emit('end', 0) if ++count == dependencies.length

  for dependency in dependencies
    asset = new Asset(dependency.source, path.resolve(dependency.target))

    asset.once 'cached', asset.copy
    asset.once 'copied', tick
    asset.cache() unless asset.isCached()

  return emitter
