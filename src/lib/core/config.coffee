fs     = require('fs')
mkdirp = require('mkdirp')
path   = require('path')

cwd  = process.cwd()
home = process.env['HOME']

# Git cache directory
cacheDir = path.join(home, '.parachute')
mkdirp(cacheDir) unless fs.existsSync(cacheDir)

jsonPath     = path.join(cwd, 'parachute.json')
dependencies = []
scripts      = {}

if fs.existsSync(jsonPath)
  dependencies = dependencies.concat(require(jsonPath).dependencies)
  scripts      = require(jsonPath).scripts

config =
  cacheDir:     cacheDir
  dependencies: dependencies
  options:
    scripts: scripts

module.exports = config
