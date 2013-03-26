# ==========================================
# BOWER: Hogan Renderer w/ template cache
# ==========================================
# Copyright 2012 Twitter, Inc
# Licensed under The MIT License
# http://opensource.org/licenses/MIT
# ==========================================

events = require('events')
hogan  = require('hogan.js')
path   = require('path')
fs     = require('fs')

require('../util/hogan-colors')

templates = {}

module.exports = (name, context, sync) ->
  emitter = new events.EventEmitter

  templateName = name + '.mustache'
  templatePath = path.join(__dirname, '../../templates/', templateName)

  if sync
    templates[templatePath] = fs.readFileSync(templatePath, 'utf-8') if (!templates[templatePath])
    return hogan.compile(templates[templatePath]).renderWithColors(context)
  else if templates[templatePath]
    process.nextTick ->
      emitter.emit('data', hogan.compile(templates[templatePath]).renderWithColors(context))
  else
    fs.readFile templatePath, 'utf-8', (err, file) ->
      return emitter.emit('error', err) if (err)

      templates[templatePath] = file
      emitter.emit('data', hogan.compile(file).renderWithColors(context))

  return emitter
