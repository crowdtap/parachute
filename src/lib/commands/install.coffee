{ EventEmitter } = require('events')
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

  count = 0
  tick  = -> emitter.emit('end', 0) if ++count == dependencies.length

  for depObj in dependencies
    dependency = new Dependency(depObj.source, depObj.target)

    dependency.on 'data',  emitter.emit.bind(emitter, 'data')
    dependency.on 'error', emitter.emit.bind(emitter, 'error')

    dependency.once 'copied', ->
      if dependency.hasPostScripts()
        dependency.on 'post_scripts_complete', tick
        dependency.runPostScripts()
      else
        tick()

    if dependency.isCached()
      if options.update
        dependency.once 'updated', dependency.copy
        dependency.update()
      else
        dependency.copy()
    else
      dependency.once 'cached', dependency.copy
      dependency.cache()

  return emitter

module.exports.line = (argv) ->
  options = nopt(optionTypes, shorthand, argv)
  if options.help
    help('install')
  else
    module.exports(config.dependencies, options)
