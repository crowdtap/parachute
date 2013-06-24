fs     = require('fs')
mkdirp = require('mkdirp')
path   = require('path')

cwd  = process.cwd()
home = process.env['HOME']

# Git cache directory
cacheDir = path.join(home, '.parachute')
fs.exists cacheDir, (exists) -> mkdirp(cacheDir) unless exists

# Dependencies from parachute.json
jsonPath = path.join(cwd, 'parachute.json')
dependencies = []
dependencies = dependencies.concat(require(jsonPath).dependencies) if fs.existsSync(jsonPath)

# Scripts
scripts = {}
scripts = require(jsonPath).scripts if fs.existsSync(jsonPath)

config =
  cacheDir:     cacheDir
  dependencies: dependencies
  options:
    scripts: scripts

module.exports = config
