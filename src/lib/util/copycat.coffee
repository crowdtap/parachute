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
  cb   = options unless cb?
  srcs = glob.sync(src)

  if srcs.length > 1 && !@isDirectoryPath(dest)
    throw new Error("#{dest} is not a directory")

  mkdirp.sync @parseDestDir(dest) unless fs.existsSync @parseDestDir(dest)

  # TODO: Call cb at the right time
  tally = 0
  for _src, i in srcs
    throw new Error("#{_src} does not exist") unless fs.existsSync(_src)
    if @isDirectoryPath(dest)
      destFilename = path.join @parseDestDir(dest), @parseFilename(_src)
    else
      destFilename = dest

    ncp _src, destFilename, options, (err) ->
      throw err if err
      cb?() if ++tally == srcs.length

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
