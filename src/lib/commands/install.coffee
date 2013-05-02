{ EventEmitter } = require('events')
Asset            = require('../core/asset')
config           = require('../core/config')

module.exports = (dependencies) ->
  emitter = new EventEmitter

  dependencies or= config.dependencies

  count = 0
  tick  = -> emitter.emit('end', 0) if ++count == dependencies.length

  for dependency in dependencies
    options =
      files:  dependency.files
      target: dependency.target
    asset = new Asset(dependency.source, options)

    asset.on 'data',  emitter.emit.bind(emitter, 'data')
    asset.on 'error', emitter.emit.bind(emitter, 'error')

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
