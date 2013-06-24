module.exports =
  dirName: ->
    dirs = process.cwd().split('/')
    dirs[dirs.length - 1]
  month: ->
    month = (new Date).getMonth() + 1
    if month < 10 then ('0' + month) else month
  day: ->
    date = (new Date).getDate()
    if date < 10 then ('0' + date) else date
  year: ->
    (new Date).getFullYear()
  date: ->
    me = module.exports
    "#{me.year()}-#{me.month()}-#{me.day()}"
