{ EventEmitter } = require('events')
Dependency       = require('./dependency')

class Manager extends EventEmitter
  constructor: (dependencies, options) ->
    @config =
      dependencies: dependencies || []
      options:      options      || {}
    @tickers = {}
    @dependencies = []

    for depObj in dependencies
      dependency = new Dependency(depObj.source, depObj.target)
      @dependencies.push(dependency)
      # TODO: Test error emissions for each method?
      dependency.on 'error', @emit.bind(@, 'error')

  resolve: ->
    for dependency in @dependencies
      if dependency.isCached()
        if @config.options.update
          dependency.update => @tick('resolved')
        else
          @tick('resolved')
      else
        dependency.cache => @tick('resolved')

  install: ->
    @on 'copied', (dependency) =>
      if dependency.hasPostScripts()
        dependency
          .on('post_scripts_complete', => @tick('installed'))
          .runPostScripts()
      else
        @tick('installed')

    for dependency in @dependencies
      if @config.options.update
        dependency.update =>
          dependency.copy => @emit('copied', dependency)
      else
        dependency.copy => @emit('copied', dependency)

  update: ->
    for dependency in @dependencies
      dependency.update => @tick('updated')

  # Private

  tick: (eventName, emitArg, cb) ->
    @tickers[eventName] ?= 0
    if emitArg? && typeof emitArg == 'function'
      cb      = emitArg
      emitArg = undefined

    if ++@tickers[eventName] == @dependencies.length
      @tickers[eventName] = 0
      @emit(eventName, emitArg || 0)
      cb?()

module.exports = Manager
