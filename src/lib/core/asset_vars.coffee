module.exports =
  dirName: ->
    dirs = process.cwd().split('/')
    dirs[dirs.length - 1]
