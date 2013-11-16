{ EventEmitter } = require('events')
Dependency       = require('./dependency')
_                = require('../util/lodash-ext')
template         = require('../util/template')
exec             = require('child_process').exec

class Manager extends EventEmitter
  constructor: (dependencies, options) ->
    @config =
      dependencies: dependencies || []
      options:      options      || {}
    @tickers = {}
    @dependencies = []

    for depObj in dependencies
      options = _.omit(depObj, 'src')
      dependency = new Dependency(depObj.src, options)
      @dependencies.push(dependency)
      dependency
        .on('data',  @emit.bind(@, 'data'))
        .on('error', @emit.bind(@, 'error'))

  resolve: ->
    @runScript('preresolve')
    @on 'resolved', => @runScript('postresolve')

    for dependency in @dependencies
      if dependency.isCached()
        if @config.options.update
          dependency.update => @tick('resolved')
        else
          @tick('resolved')
      else
        dependency.cache => @tick('resolved')

  install: ->
    @runScript('preinstall')
    @on 'installed', => @runScript('postinstall')

    for dependency in @dependencies
      dependency.copy => @tick('installed')

  update: ->
    for dependency in @dependencies
      dependency.update => @tick('updated')

  runScript: (scriptName) ->
    if (line = @config.options.scripts?[scriptName])?
      exec line, (err, stdout, stderr) =>
        @emit('error', err)    if err?
        @emit('error', stderr) if stderr?.length
        @emit('data',  stdout) if stdout?.length
        template('script', { which: scriptName, command: line })
          .on 'data', @emit.bind(@, 'data')

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
