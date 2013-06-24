describe 'preprocessors html2js', ->
  expect = require('chai').expect;

  html2js = require '../lib/html2js'
  logger = create: -> {debug: ->}
  process = null

  # TODO(vojta): refactor this somehow ;-) it's copy pasted from lib/file-list.js
  File = (path, mtime) ->
    @path = path
    @originalPath = path
    @contentPath = path
    @mtime = mtime
    @isUrl = false

  removeSpacesFrom = (str) ->
    str.replace /[\s\n]/g, ''

  beforeEach ->
    process = html2js logger, '/base'


  it 'should convert html to js code', (done) ->
    file = new File '/base/path/file.html'

    HTML = '<html></html>'
    RESULT = 'angular.module(\'path/file.html\',[]).run(function($templateCache){' +
      '$templateCache.put(\'path/file.html\',\'<html></html>\');' +
    '});'

    process HTML, file, (processedContent) ->
      expect(removeSpacesFrom processedContent).to.equal RESULT
      done()


  it 'should change path to *.js', (done) ->
    file = new File '/base/path/file.html'

    process '', file, (processedContent) ->
      expect(file.path).to.equal '/base/path/file.html.js'
      done()


  it 'should preserve new lines', (done) ->
    file = new File '/base/path/file.html'

    process 'first\nsecond', file, (processedContent) ->
      expect(removeSpacesFrom processedContent).to.contain "'first\\n'+'second'"
      done()

  it 'should preserve Windows new lines', (done) ->
    file = new File '/base/path/file.html'

    process 'first\r\nsecond', file, (processedContent) ->
      expect(processedContent).to.not.contain '\r'
      done()

  it 'should preserve the backslash character', (done) ->
    file = new File '/base/path/file.html'

    process 'first\\second', file, (processedContent) ->
      expect(removeSpacesFrom processedContent).to.contain "'first\\\\second'"
      done()
