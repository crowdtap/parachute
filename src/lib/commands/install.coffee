{ EventEmitter } = require('events')
Asset            = require('../core/asset')
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

  count = 0
  tick  = -> emitter.emit('end', 0) if ++count == dependencies.length

  for dependency in dependencies
    asset = new Asset(dependency.source, dependency.target)

    asset.on 'data',  emitter.emit.bind(emitter, 'data')
    asset.on 'error', emitter.emit.bind(emitter, 'error')

    asset.once 'copied', ->
      if asset.hasPostScripts()
        asset.on 'post_scripts_complete', tick
        asset.runPostScripts()
      else
        tick()

    if asset.isCached()
      if options.update
        asset.once 'updated', asset.copy
        asset.update()
      else
        asset.copy()
    else
      asset.once 'cached', asset.copy
      asset.cache()

  return emitter

module.exports.line = (argv) ->
  options = nopt(optionTypes, shorthand, argv)
  if options.help
    help('install')
  else
    module.exports(config.dependencies, options)
