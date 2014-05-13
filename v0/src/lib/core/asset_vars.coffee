_ = require('../util/lodash-ext')

module.exports =
  dirName: ->
    dirs = process.cwd().split('/')
    dirs[dirs.length - 1]

  month: ->
    _.lpad((new Date).getMonth() + 1, 2)

  day: ->
    _.lpad((new Date).getDate(), 2)

  year: ->
    (new Date).getFullYear()

  date: ->
    me = module.exports
    "#{me.year()}-#{me.month()}-#{me.day()}"
