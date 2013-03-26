fs     = require('fs')
spawn  = require('child_process').spawn
config = require('../core/config')

module.exports = (args, options) ->
  console.log('git-wrapper')
  options = options || {}
  options =
    cwd: options.cwd || process.cwd()

  child = spawn('git', args, options)

  child.on 'exit', (code) ->
    console.log "git did not exit cleanly!" if code == 128

  child
