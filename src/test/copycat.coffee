copycat    = require('../lib/util/copycat')
fs         = require('fs')
expect     = require('expect.js')
rimraf     = require('rimraf')

describe 'xxx copycat', ->
  cwd     = process.cwd()
  testDir = "#{__dirname}/install_test"

  process.env['HOME'] = testDir

  clean = (done) ->
    rimraf testDir, (err) ->
      throw new Error('Unable to remove install directory') if err
      done?()

  beforeEach (done) ->
    process.chdir cwd
    clean ->
      fs.mkdir testDir, (err) ->
        throw err if err
        process.chdir testDir
        done?()

  after (done) ->
    process.chdir cwd
    clean(done)

  describe '#copy', ->

  describe '#isDirectoryPath', ->
    it 'determines if the path appears to be a directory path', (done) ->
      expect(copycat.isDirectoryPath('foo')).to.be(false)
      expect(copycat.isDirectoryPath('foo/')).to.be(true)
      done()

  describe '#parseDestDir', ->
    it 'derives the destination directory from the path', (done) ->
      expect(copycat.parseDestDir('foo/bar/')).to.be('foo/bar/')
      expect(copycat.parseDestDir('foo/bar/baz.txt')).to.be('foo/bar/')
      done()

  describe '#parseFilename', ->
    it 'derives the destination directory from the path', (done) ->
      expect(copycat.parseFilename('foo/bar/baz.txt')).to.be('baz.txt')
      done()

    it 'returns an empty string if path is a directory', (done) ->
      expect(copycat.parseFilename('foo/bar/')).to.eql('')
      done()
