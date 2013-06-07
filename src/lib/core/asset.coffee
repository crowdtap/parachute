{ EventEmitter } = require('events')
assetVars        = require('./asset_vars')
git              = require('../util/git-wrapper')
template         = require('../util/template')
fs               = require('fs')
gift             = require('gift')
mkdirp           = require('mkdirp')
ncp              = require('ncp')
path             = require('path')
spawn            = require('child_process').spawn

class Asset extends EventEmitter
  constructor: (@source, target) ->
    # Recognize git source URL parameters:
    # [original str, http(s), git@, host, trailing path]
    gitRegex     = /(\w+:\/\/)?(.+@)*([\w\d\.]+):?\/*(.*)/
    pathSegments = @source.match(gitRegex)

    @name      = pathSegments[4].replace('/','-').replace('.git','')
    @cacheDir  = path.join(process.env['HOME'], '.parachute', @name)
    @targetDir = target || process.cwd()
    @remote    = pathSegments[1]? || pathSegments[2]?
    @source    = path.resolve(@source) unless @remote
    @repo      = gift @cacheDir

  cache: (callback) ->
    template('action', { doing: 'caching', what: @source })
      .on 'data', @emit.bind(@, 'data')
    # TODO: Check if @source is local and exists
    cp = git(['clone', @source, @cacheDir])
    cp.on 'exit', (status) =>
      @emit 'cached', status
      callback?(status)

  copy: (callback) ->
    console.log "[Asset] #copy"
    console.log "[ls] - #{fs.readdirSync('.')}"
    if @isCached()
      @repo.status (err, status) =>
        if status.clean
          fs.exists "#{@cacheDir}/assets.json", (hasJson) =>
            copyType = if hasJson then 'custom' else 'full'
            @["#{copyType}Copy"](callback)
            template('action', { doing: 'copying', what: @source })
              .on 'data', @emit.bind(@, 'data')
        else
          @emit 'error', message: 'asset cache is dirty'
    else
      @emit 'error', message: 'asset is not cached'

  hasPostScripts: ->
    if @isCached()
      fs.existsSync path.join(@cacheDir, 'post_scripts')
    else
      @emit 'error', message: 'asset is not cached'

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
      @emit 'error', message: 'asset is not cached'

  update: (callback) ->
    @repo.status (err, status) =>
      if status.clean
        template('action', { doing: 'Updating', what: @name })
          .on 'data', @emit.bind(@, 'data')
        cp = git(['pull', 'origin', 'master'], cwd: @cacheDir)
        cp.on 'exit', (status) =>
          @emit 'updated', status
          callback?()
      else
        @emit 'error', message: "'#{@name}' repo is dirty, please resolve changes"


  # Private

  customCopy: (callback) ->
    componentsJson = JSON.parse fs.readFileSync("#{@cacheDir}/assets.json")
    components     = componentsJson.components

    console.log "[Asset] #customCopy"
    console.log "[ls] - #{fs.readdirSync('.')}"

    if components?.length
      next = (err) =>
        throw err if err
        if components.length
          copyNextComponent()
        else
          @emit 'copied', 0
          callback?(0)

      copyNextComponent = =>
        component = components.shift()
        source    = path.join @cacheDir, component.source
        dest      = @subVariables path.join(@targetDir, component.target)

        console.log "[Asset] #customCopy - copyNextComponent"
        console.log "component - #{JSON.stringify(component, null, 2)}"
        console.log "[ls] - #{fs.readdirSync('.')}"

        # Evaluate destination and extract destination directory
        if dest.indexOf('/', dest.length - '/'.length) != -1
          console.log "[Asset] #customCopy - dest is directory"
          destDir = dest
        else
          console.log "[Asset] #customCopy - dest is NOT directory"
          destDir = dest.split('/').slice(0, -1).join('/')

        console.log "[Asset] #customCopy - dest: #{dest}"
        console.log "[Asset] #customCopy - destDir: #{destDir}"

        fs.exists destDir, (destDirExists) =>
          if destDirExists
            console.log "[Asset] #customCopy - destDirExists"
            @ncp source, dest, next
          else
            console.log "[Asset] #customCopy - destDirExists is false"
            mkdirp destDir, (err) =>
              throw err if err
              @ncp source, dest, next

      copyNextComponent()
    else
      @fullCopy(callback)

  fullCopy: (callback) ->
    fs.exists @targetDir, (exists) =>
      mkdirp.sync(@targetDir) unless exists
      @ncp @cacheDir, @targetDir, (err) =>
        @emit 'copied', 0
        callback?(0)

  ncp: (source, dest, callback) ->
    console.log "[Asset] #ncp"
    console.log "source - #{source}"
    console.log "dest - #{dest}"
    console.log "[ls] - #{fs.readdirSync('.')}"
    console.log "[ls css] - #{fs.readdirSync('css')}"
    console.log "[ls css/shared] - #{fs.readdirSync('css/shared')}"
    stats = fs.lstatSync('css/shared')
    console.log "[css/shared isDirectory?] #{stats.isDirectory()}"

    ignore  = [/\.git/, /assets.json/, /post_scripts/]
    options =
      clobber: true
      filter: (filename) ->
        for regexp in ignore
          return false if filename.match(regexp)?.length
        return true

    ncp source, dest, options, (err) =>
      if err
        console.log "[Asset] #ncp - error: #{err}"
        throw err
      callback?(0)

  subVariables: (string) ->
    for variable in string.match(/{{(\w+)}}/g) || []
      key = variable.slice(2, -2)
      string = string.replace(variable, assetVars[key])
    string

module.exports = Asset
