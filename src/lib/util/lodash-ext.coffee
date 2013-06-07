# Lodash wrapper with extensions.
#
# ===============================

_ = require('lodash')

_.mixin
  endsWith: (str, suffix) ->
    str.indexOf(suffix, str.length - suffix.length) != -1

module.exports = _
