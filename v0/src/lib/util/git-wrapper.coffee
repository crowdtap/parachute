_      = require('lodash')
fs     = require('fs')
spawn  = require('child_process').spawn
config = require('../core/config')

module.exports = (args, options) ->
  options ?= {}
  defaults =
    cwd: process.cwd()
    verbose: true

  options = _.extend({}, defaults, options)

  child = spawn 'git', args, _.omit(options, 'verbose')

  child.on 'exit', (code) ->
    console.log "git did not exit cleanly!" if code is 128

  if options.verbose
    child.stderr.on 'data', (data) ->
      console.log "\n#{data.toString()}"

  child
