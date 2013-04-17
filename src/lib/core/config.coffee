fs     = require('fs')
mkdirp = require('mkdirp')
path   = require('path')

cwd  = process.cwd()
home = process.env['HOME']

# Git cache directory
cacheDir = path.join(home, '.parachute')
fs.exists cacheDir, (exists) -> mkdirp(cacheDir) unless exists

# Dependencies from assets.json
jsonPath = path.join(cwd, 'assets.json')
dependencies = []
dependencies = dependencies.concat(require(jsonPath).dependencies) if fs.existsSync(jsonPath)

config =
  cacheDir: cacheDir
  dependencies: dependencies

module.exports = config
