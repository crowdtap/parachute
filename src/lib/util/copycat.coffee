# Copycat!
#
# Recursive file copy utility which makes any intermediate directories as
# needed.
#
# =======================================================================

_      = require('./lodash-ext')
fs     = require('fs')
ncp    = require('ncp')
glob   = require('glob')
path   = require('path')
mkdirp = require('mkdirp')

module.exports.copy = (src, dest, options, cb) ->
  cb      = options unless cb?
  srcs    = glob.sync(src)
  destDir = @parseDestDir(dest)

  if srcs.length > 1 && !@isDirectoryPath(dest)
    throw new Error("#{dest} is not a directory")

  mkdirp.sync(destDir) unless fs.existsSync(destDir)

  tally = 0
  for _src, i in srcs
    throw new Error("#{_src} does not exist") unless fs.existsSync(_src)
    srcFile = @parseFilename(_src)
    _dest   = @isDirectoryPath(dest) && path.join(destDir, srcFile) || dest

    ncp _src, _dest, options, (err) ->
      throw err if err
      cb?() if ++tally == srcs.length

module.exports.isDirectoryPath = (pathString) ->
  _.endsWith(pathString, '/') ||
    fs.existsSync(pathString) && fs.statSync(pathString).isDirectory()

module.exports.parseDestDir = (pathString) ->
  if @isDirectoryPath(pathString)
    pathString
  else
    pathString.split('/').slice(0, -1).join('/') + '/'

module.exports.parseFilename = (pathString) ->
  if @isDirectoryPath(pathString) then '' else _.last(pathString.split('/'))
