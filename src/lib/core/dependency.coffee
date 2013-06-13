{ EventEmitter } = require('events')
assetVars        = require('./asset_vars')
copycat          = require('../util/copycat')
git              = require('../util/git-wrapper')
template         = require('../util/template')
fs               = require('fs')
gift             = require('gift')
path             = require('path')
spawn            = require('child_process').spawn

class Dependency extends EventEmitter
  constructor: (@source, dest) ->
    # Recognize git source URL parameters:
    # [original str, http(s), git@, host, trailing path]
    gitRegex     = /(\w+:\/\/)?(.+@)*([\w\d\.]+):?\/*(.*)/
    pathSegments = @source.match(gitRegex)

    @name      = pathSegments[4].replace('/','-').replace('.git','')
    @cacheDir  = path.join(process.env['HOME'], '.parachute', @name)
    @destDir   = dest || process.cwd()
    @remote    = pathSegments[1]? || pathSegments[2]?
    @source    = path.resolve(@source) unless @remote
    @repo      = gift @cacheDir

    @ncpOptions =
      clobber: true
      filter: (filename) ->
        ignore  = [/\.git/, /assets.json/, /post_scripts/]
        for regexp in ignore
          return false if filename.match(regexp)?.length
        return true

  cache: (cb) ->
    template('action', { doing: 'caching', what: @source })
      .on 'data', @emit.bind(@, 'data')
    # TODO: Check if @source is local and exists
    cp = git(['clone', @source, @cacheDir])
    cp.on 'exit', (status) =>
      @emit 'cached', status
      cb?(status)

  copy: (cb) ->
    if @isCached()
      @repo.status (err, status) =>
        if status.clean
          fs.exists "#{@cacheDir}/assets.json", (hasJson) =>
            copyType = if hasJson then 'custom' else 'full'
            @["#{copyType}Copy"](cb)
            template('action', { doing: 'copying', what: @source })
              .on 'data', @emit.bind(@, 'data')
        else
          @emit 'error', message: 'dependency cache is dirty'
    else
      @emit 'error', message: 'dependency is not cached'

  hasPostScripts: ->
    if @isCached()
      fs.existsSync path.join(@cacheDir, 'post_scripts')
    else
      @emit 'error', message: 'dependency is not cached'

  isCached: ->
    fs.existsSync(@cacheDir)

  runPostScripts: ->
    if @isCached()
      postScriptsDir = path.join @cacheDir, 'post_scripts'
      scripts_queue  = fs.readdirSync postScriptsDir

      do execNextScript = =>
        if (filename = scripts_queue.shift())?
          filepath = path.join(postScriptsDir, filename)
          if fs.statSync(filepath).isFile()
            template('action', { doing: 'post script', what: filename })
              .on 'data', @emit.bind(@, 'data')
            spawn('sh', [filepath]).on('exit', execNextScript)
        else
          @emit 'post_scripts_complete'
    else
      @emit 'error', message: 'dependency is not cached'

  update: (cb) ->
    @repo.status (err, status) =>
      if status.clean
        template('action', { doing: 'Updating', what: @name })
          .on 'data', @emit.bind(@, 'data')
        cp = git(['pull', 'origin', 'master'], cwd: @cacheDir)
        cp.on 'exit', (status) =>
          @emit 'updated', status
          cb?()
      else
        @emit 'error', message: "'#{@name}' repo is dirty, please resolve changes"

  # Private

  customCopy: (cb) ->
    componentsJson = JSON.parse fs.readFileSync("#{@cacheDir}/assets.json")
    components     = componentsJson.components

    if components?.length
      next = (err) =>
        throw err if err
        if components.length
          copyNextComponent()
        else
          @emit 'copied', 0
          cb?(0)

      do copyNextComponent = =>
        component = components.shift()
        source    = path.join @cacheDir, component.src
        dest      = @subVariables path.join(@destDir, component.dest)

        copycat.copy(source, dest, @ncpOptions, next)
    else
      @fullCopy(cb)

  fullCopy: (cb) ->
    copycat.copy @cacheDir, @destDir, @ncpOptions, (err) =>
      @emit 'copied', 0
      cb?(0)

  subVariables: (string) ->
    for variable in string.match(/{{(\w+)}}/g) || []
      key = variable.slice(2, -2)
      string = string.replace(variable, assetVars[key])
    string

module.exports = Dependency
