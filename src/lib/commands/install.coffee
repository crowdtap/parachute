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
    asset = new Asset(dependency.source, dependency.target)

    asset.on 'data', emitter.emit.bind(emitter, 'data')
    asset.once 'copied', ->
      if asset.hasPostScripts()
        asset.on 'post_scripts_complete', tick
        asset.runPostScripts()
      else
        tick()

    if asset.isCached()
      asset.copy()
    else
      asset.once 'cached', asset.copy
      asset.cache()

  return emitter
