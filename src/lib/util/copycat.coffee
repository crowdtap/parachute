# Copycat!
#
# Recursive file copy utility which makes any intermediate directories as
# needed.
#
# =======================================================================

_      = require('./lodash-ext')
fs     = require('fs')
ncp    = require('ncp')
path   = require('path')
mkdirp = require('mkdirp')

module.exports.copy = (src, dest, options, cb) ->
  throw new Error("#{src} does not exist") unless fs.existsSync(src)

  cb = options unless cb?

  if @isDirectoryPath(dest)
    destDir     = dest
    srcFilename = @parseFilename(src)
    dest        = path.join(dest, srcFilename)
  else
    destDir = @parseDestDir(dest)

  mkdirp.sync(destDir) unless fs.existsSync(dest)

  ncp src, dest, options, (err) ->
    throw err if err
    cb?()

module.exports.isDirectoryPath = (pathString) ->
  _.endsWith(pathString, '/') ||
    fs.existsSync(pathString) && fs.statSync(pathString).isDirectory()

module.exports.parseDestDir = (pathString) ->
  if @isDirectoryPath(pathString)
    pathString
  else
    pathString.split('/').slice(0, -1).join('/')

module.exports.parseFilename = (pathString) ->
  if @isDirectoryPath(pathString) then '' else _.last(pathString.split('/'))
