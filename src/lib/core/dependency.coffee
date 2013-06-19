{ EventEmitter } = require('events')
assetVars        = require('./asset_vars')
copycat          = require('../util/copycat')
git              = require('../util/git-wrapper')
template         = require('../util/template')
_                = require('../util/lodash-ext')
fs               = require('fs')
gift             = require('gift')
path             = require('path')
spawn            = require('child_process').spawn

class Dependency extends EventEmitter
  constructor: (@src, options) ->
    # Recognize git source URL parameters:
    # [original str, http(s), git@, host, trailing path]
    gitRegex     = /(\w+:\/\/)?(.+@)*([\w\d\.]+):?\/*(.*)/
    pathSegments = @src.match(gitRegex)

    @name       = pathSegments[4].replace('/','-').replace('.git','')
    @cacheDir   = path.join(process.env['HOME'], '.parachute', @name)
    @root       = options?.root || process.cwd()
    @remote     = pathSegments[1]? || pathSegments[2]?
    @src        = path.resolve(@src) unless @remote
    @repo       = gift @cacheDir
    @components = options?.components && @parseComponents(options.components)

    @ncpOptions =
      clobber: true
      filter: (filename) ->
        ignore = [/\.git/, /parachute.json/, /post_scripts/]
        !_.detect ignore, (regexp) -> filename.match(regexp)?.length

  cache: (cb) ->
    template('action', { doing: 'caching', what: @src })
      .on 'data', @emit.bind(@, 'data')
    # TODO: Check if @src is local and exists
    cp = git(['clone', @src, @cacheDir])
    cp.on 'exit', (status) =>
      @emit 'cached', status
      cb?(status)

  copy: (cb) ->
    if @isCached()
      @repo.status (err, status) =>
        if status.clean
          @copyComponents(cb)
          template('action', { doing: 'copying', what: @src })
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

  parseComponents: (components) ->
    _.map components, (item) ->
      if typeof item == 'string' then { src: item, dest: null } else item

  sourceComponents: ->
    if fs.existsSync "#{@cacheDir}/parachute.json"
      JSON.parse(fs.readFileSync("#{@cacheDir}/parachute.json")).components

  copyComponents: (cb) ->
    components = @components || @sourceComponents() || [ src: null, dest: null ]
    components = _.map components, (component) =>
      componentWithAbsPaths =
        src:  path.join(@cacheDir, component.src  || '')
        dest: path.join(@root,     component.dest || '')
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
        copycat.copy(component.src, @subVariables(component.dest), @ncpOptions, next)

  subVariables: (string) ->
    for variable in string.match(/{{(\w+)}}/g) || []
      key    = variable.slice(2, -2)
      string = string.replace(variable, assetVars[key])
    string

module.exports = Dependency
