{ EventEmitter } = require('events')
assetVars        = require('./asset_vars')
git              = require('../util/git-wrapper')
fs               = require('fs')
mkdirp           = require('mkdirp')
ncp              = require('ncp')
path             = require('path')

class Asset extends EventEmitter
  constructor: (@source, target) ->
    # Recognize git source URL parameters:
    # [original str, http(s), git@, host, trailing path]
    gitRegex     = /(\w+:\/\/)?(.+@)*([\w\d\.]+):?\/*(.*)/
    pathSegments = @source.match(gitRegex)

    @name      = pathSegments[4].replace('/','-').replace('.git','')
    @cacheDir  = "#{process.cwd()}/.parachute/#{@name}"
    @targetDir = target || process.cwd()
    @remote    = pathSegments[1]? || pathSegments[2]?

  cache: (callback) ->
    cp = git(['clone', @source, @cacheDir])
    cp.on 'exit', (status) =>
      @emit 'cached', status
      callback(status) if callback?()

  copy: (callback) ->
    if @isCached()
      fs.exists "#{@cacheDir}/assets.json", (hasJson) =>
        copyType = if hasJson then 'custom' else 'full'
        @["#{copyType}Copy"](callback)
    else
      @emit 'error', message: 'asset is not cached'

  isCached: ->
    fs.existsSync(@cacheDir)

  # Pseudo-private functions

  customCopy: (callback) ->
    componentsJson = require("#{@cacheDir}/assets.json")
    components     = componentsJson.components

    if components?.length
      count = 0
      tick = ->
        count++
        if count == components.length && callback?()
          @emit 'copied', 0
          callback(0) if callback?()

      for component in components
        source = path.join @cacheDir, component.source
        target = @subVariables(path.join process.cwd(), component.target)

        fs.exists target, (targetExists) =>
          if targetExists
            @ncp source, target, tick
          else
            mkdirp target, (err) =>
              throw err if err
              @ncp source, target, tick
    else
      @fullCopy(callback)

  fullCopy: (callback) ->
    fs.exists @targetDir, (exists) =>
      mkdirp.sync(@targetDir) unless exists
      @ncp @cacheDir, @targetDir, =>
        @emit 'copied', 0
        callback(0) if callback?()

  ncp: (source, dest, callback) ->
    ignore  = [/\.git/, 'assets.json']
    options =
      clobber: true
      filter: (filename) ->
        for regexp in ignore
          return false if filename.match(regexp)?.length
        return true

    ncp source, dest, options, (err) =>
      throw err if err
      callback(0) if callback?()

  subVariables: (string) ->
    matches = string.match(/{{(\w+)}}/g)
    return string unless matches

    for variable in matches
      key = variable.slice(2, -2)
      string = string.replace(variable, assetVars[key])
    string

module.exports = Asset
