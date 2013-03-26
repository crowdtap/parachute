fs     = require('fs')
mkdirp = require('mkdirp')
path   = require('path')

cacheDir = path.join(process.cwd(), '.parachute')

fs.exists cacheDir, (exists) ->
  mkdirp(cacheDir) unless exists

config =
  cacheDir: cacheDir

module.exports = config
