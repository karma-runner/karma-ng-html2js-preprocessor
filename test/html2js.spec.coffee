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

  it 'should not append *.js to a processed file\'s path more than once', (done) ->
    file = new File '/base/path/file.html'

    process '', file, (processedContent) ->
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


    describe 'stripSuffix', ->
      beforeEach ->
        process = createPreprocessor stripSuffix: '.ext'

      it 'strips the given suffix from the file path', (done) ->
        file = new File 'file.html.ext'
        HTML = '<html></html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.defineModule('file.html').and
            .to.defineTemplateId('file.html').and
            .to.haveContent HTML
          done()


    describe 'stripSufix', ->
      beforeEach ->
        process = createPreprocessor stripSufix: '.ext'


      it 'strips the given sufix from the file path', (done) ->
        file = new File 'file.html.ext'
        HTML = '<html></html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.defineModule('file.html').and
            .to.defineTemplateId('file.html').and
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
      it 'should generate code with a given module name', ->
        process = createPreprocessor
          moduleName: 'foo'
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


      it 'should generate code with multiple module names', ->
        process = createPreprocessor
          moduleName: (htmlPath) ->
            module = htmlPath.split('/')[0]
            if module != 'tpl'
              module

        file1 = new File '/base/app/one.html'
        HTML1 = '<span>one</span>'
        file2 = new File '/base/common/two.html'
        HTML2 = '<span>two</span>'
        file3 = new File '/base/tpl/three.html'
        HTML3 = '<span>three</span>'
        threeFilesContent = ''

        process HTML1, file1, (processedContent) ->
          threeFilesContent += processedContent

        process HTML2, file2, (processedContent) ->
          threeFilesContent += processedContent

        process HTML3, file3, (processedContent) ->
          threeFilesContent += processedContent

        # evaluate three files (to simulate multiple module names)
        expect(threeFilesContent)
          .to.defineModule('app').and
          .to.defineTemplateId('app/one.html').and
          .to.haveContent(HTML1).and
          .to.defineModule('common').and
          .to.defineTemplateId('common/two.html').and
          .to.haveContent(HTML2)
          .to.defineModule('tpl/three.html').and
          .to.defineTemplateId('tpl/three.html').and
          .to.haveContent(HTML3)

    describe 'RequireJS', ->
      it 'should wrap module with require', (done) ->
        process = createPreprocessor
          enableRequireJs: true

        file = new File '/base/path/file.html'
        HTML = '<html>test me!</html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.requireModule('angular')
            .to.defineModule('path/file.html')
            .to.defineTemplateId('path/file.html').and
            .to.haveContent HTML
          done()

      it 'should use custom angular module ID', (done) ->
        process = createPreprocessor
          enableRequireJs: true
          requireJsAngularId: 'foo'

        file = new File '/base/path/file.html'
        HTML = '<html>test me!</html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.requireModule('foo')
            .to.defineModule('path/file.html')
            .to.defineTemplateId('path/file.html').and
            .to.haveContent HTML
          done()

    describe 'angular version 2', ->
      it 'should store the template in window.$templateCache', (done) ->
        process = createPreprocessor
          angular: 2

        file = new File '/base/path/file.html'
        HTML  = '<html>test</html>'

        process HTML, file, (processedContent) ->
          expect(processedContent)
            .to.defineAngular2TemplateId('path/file.html').and
            .to.haveContent HTML
          done()
