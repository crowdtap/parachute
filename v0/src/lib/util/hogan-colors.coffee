# ==========================================
# BOWER: Hogan.js renderWithColors extension
# ==========================================
# Copyright 2012 Twitter, Inc
# Licensed under The MIT License
# http://opensource.org/licenses/MIT
# ==========================================

colors = require('colors')
hogan  = require('hogan.js')
_      = require('lodash')
nopt   = require('nopt')

module.exports = hogan.Template.prototype.renderWithColors = (context, partials, indent) ->
  #colors.mode = 'none' unless nopt(process.argv).color

  context = _.extend({
    yellow : (s) -> s.yellow
    green  : (s) -> s.green
    cyan   : (s) -> s.cyan
    red    : (s) -> s.red
    white  : (s) -> s.white
  }, context)
  this.ri([context], partials || {}, indent)
