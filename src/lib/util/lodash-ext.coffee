# Lodash wrapper with extensions.
#
# ===============================

_ = require('lodash')

_.mixin
  endsWith: (str, suffix) ->
    str.indexOf(suffix, str.length - suffix.length) != -1
  lpad: (str, digits) ->
    Array(digits - str.length + 1).join('0') + str

module.exports = _
