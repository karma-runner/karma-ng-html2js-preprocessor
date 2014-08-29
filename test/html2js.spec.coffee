describe 'preprocessors html2js', ->
  chai = require('chai')

  templateHelpers = require('./helpers/template_cache')
  chai.use(templateHelpers)

  expect = chai.expect

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

  createPreprocessor = (config = {}) ->
    html2js logger, '/base', config

  beforeEach ->
    process = createPreprocessor()

  it 'should convert html to js code', (done) ->
    file = new File '/base/path/file.html'
    HTML = '<html>test me!</html>'

    process HTML, file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('path/file.html').and
        .to.defineTemplateId('path/file.html').and
        .to.haveContent HTML
      done()


  it 'should change path to *.js', (done) ->
    file = new File '/base/path/file.html'

    process '', file, (processedContent) ->
      expect(file.path).to.equal '/base/path/file.html.js'
      done()


  it 'should preserve new lines', (done) ->
    file = new File '/base/path/file.html'

    process 'first\nsecond', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('path/file.html').and
        .to.defineTemplateId('path/file.html').and
        .to.haveContent 'first\nsecond'
      done()


  it 'should preserve Windows new lines', (done) ->
    file = new File '/base/path/file.html'

    process 'first\r\nsecond', file, (processedContent) ->
      expect(processedContent).to.not.contain '\r'
      done()


  it 'should preserve the backslash character', (done) ->
    file = new File '/base/path/file.html'

    process 'first\\second', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('path/file.html').and
        .to.defineTemplateId('path/file.html').and
        .to.haveContent 'first\\second'
      done()

  it 'should split out type="text/ng-template"', (done) ->
    file = new File '/base/path/file.html'

    process '<script id="foo" type="text/ng-template">Foo</script>', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('foo').and
        .to.defineTemplateId('foo').and
        .to.haveContent 'Foo'
      done()

  it 'should split out type="text/ng-template" with id second', (done) ->
    file = new File '/base/path/file.html'

    process '<script type="text/ng-template" id="foo">Foo</script>', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('foo').and
        .to.defineTemplateId('foo').and
        .to.haveContent 'Foo'
      done()

  it 'should split out type="text/ng-template" with id second and other attributes', (done) ->
    file = new File '/base/path/file.html'

    process '<script name="whut" type="text/ng-template" class="none" id="foo" ng-something>Foo</script>', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('foo').and
        .to.defineTemplateId('foo').and
        .to.haveContent 'Foo'
      done()

  it 'should split out type="text/ng-template" and original template', (done) ->
    file = new File '/base/path/file.html'

    process 'before <script id="foo" type="text/ng-template">Foo</script> after', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('foo').and
        .to.defineTemplateId('foo').and
        .to.haveContent 'Foo'
      expect(processedContent)
        .to.defineModule('path/file.html').and
        .to.defineTemplateId('path/file.html').and
        .to.haveContent 'before  after'
      done()

  it 'should handle newlines in type="text/ng-template"', (done) ->
    file = new File '/base/path/file.html'

    process '<script\ntype="text/ng-template"\nid="foo">\nFoo\nBoo\n</script>', file, (processedContent) ->
      expect(processedContent)
        .to.defineModule('foo').and
        .to.defineTemplateId('foo').and
        .to.haveContent '\nFoo\nBoo\n'
      done()

  describe 'options', ->
    describe 'stripPrefix', ->
      beforeEach ->
        process = createPreprocessor stripPrefix: 'path/'


      it 'strips the given prefix from the file path', (done) ->
        file = new File '/base/path/file.html'
        HTML = '<html></html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.defineModule('file.html').and
            .to.defineTemplateId('file.html').and
            .to.haveContent HTML
          done()


    describe 'prependPrefix', ->
      beforeEach ->
        process = createPreprocessor prependPrefix: 'served/'


      it 'prepends the given prefix from the file path', (done) ->
        file = new File '/base/path/file.html'
        HTML = '<html></html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.defineModule('served/path/file.html').and
            .to.defineTemplateId('served/path/file.html').and
            .to.haveContent HTML
          done()


    describe 'cacheIdFromPath', ->
      beforeEach ->
        process = createPreprocessor
          cacheIdFromPath: (filePath) -> "generated_id_for/#{filePath}"


      it 'invokes custom transform function', (done) ->
        file = new File '/base/path/file.html'
        HTML = '<html></html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.defineModule('generated_id_for/path/file.html').and
            .to.defineTemplateId('generated_id_for/path/file.html').and
            .to.haveContent HTML
          done()

    describe 'moduleName', ->
      beforeEach ->
        process = createPreprocessor
          moduleName: 'foo'

      it 'should generate code with a given module name', ->
        file1 = new File '/base/tpl/one.html'
        HTML1 = '<span>one</span>'
        file2 = new File '/base/tpl/two.html'
        HTML2 = '<span>two</span>'
        bothFilesContent = ''

        process HTML1, file1, (processedContent) ->
          bothFilesContent += processedContent

        process HTML2, file2, (processedContent) ->
          bothFilesContent += processedContent

        # evaluate both files (to simulate multiple files in the browser)
        expect(bothFilesContent)
          .to.defineModule('foo').and
          .to.defineTemplateId('tpl/one.html').and
          .to.haveContent(HTML1).and
          .to.defineTemplateId('tpl/two.html').and
          .to.haveContent(HTML2)
