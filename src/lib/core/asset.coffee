{ EventEmitter } = require('events')
git              = require('../util/git-wrapper')

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

  cache: ->
    cp = git(['clone', @source, @cacheDir])
    cp.on 'exit', (status) ->
      @emit 'cached', status

module.exports = Asset
