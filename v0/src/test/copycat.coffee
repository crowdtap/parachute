copycat    = require('../lib/util/copycat')
fs         = require('fs')
expect     = require('expect.js')
rimraf     = require('rimraf')

describe 'copycat', ->
  cwd     = process.cwd()
  testDir = "#{__dirname}/install_test"

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
    it 'throws an error if copying a glob path into a single file', (done) ->
      fs.writeFileSync('bar.txt', '')
      fs.writeFileSync('baz.txt', '')
      try
        copycat.copy('*.txt', 'foo/what.txt')
      catch e
        expect(e.message).to.eql('foo/what.txt is not a directory')
        done()

    it 'throws an error if copying a file that does not exist', (done) ->
      try
        copycat.copy('nonexistent.txt', 'foo/what.txt')
      catch e
        expect(e.message).to.eql('no files matching nonexistent.txt')
        done()

    it 'can copy a single file path to a single file path', (done) ->
      fs.writeFileSync('foo.txt', '')
      copycat.copy 'foo.txt', 'bar.txt', ->
        expect(fs.existsSync('bar.txt')).to.be(true)
        done()

    it 'can copy a single file path to a directory path', (done) ->
      fs.writeFileSync('foo.txt', '')
      fs.mkdirSync('some_dir')
      copycat.copy 'foo.txt', 'some_dir/', ->
        expect(fs.existsSync('some_dir/foo.txt')).to.be(true)
        done()

    it 'can copy a glob file path to a directory path', (done) ->
      fs.writeFileSync('foo.txt', '')
      fs.writeFileSync('bar.txt', '')
      fs.writeFileSync('baz.js', '')
      fs.mkdirSync('some_dir')
      copycat.copy '*.txt', 'some_dir/', ->
        expect(fs.existsSync('some_dir/foo.txt')).to.be(true)
        expect(fs.existsSync('some_dir/bar.txt')).to.be(true)
        expect(fs.existsSync('some_dir/baz.js')).to.be(false)
        done()

    it 'can copy a directory path to a directory path recursively', (done) ->
      fs.mkdirSync('src_dir')
      fs.mkdirSync('dest_dir')
      fs.writeFileSync('src_dir/foo.txt', '')
      fs.writeFileSync('src_dir/bar.txt', '')
      copycat.copy 'src_dir/', 'dest_dir/', ->
        expect(fs.existsSync('dest_dir/foo.txt')).to.be(true)
        expect(fs.existsSync('dest_dir/bar.txt')).to.be(true)
        done()

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
