vm = require('vm')
sinon = require('sinon');

module.exports = (chai, utils) ->

  class AngularModule
    constructor: (@name, @deps) ->
      templates = @templates = {}

    run: (block) ->
			# Block is an annotation array ["$templateCache", function($templateCache) {..}]
      block[1]
        put: (id, content) =>
          @templates[id] = content


  # Evaluates generated js code fot the template cache
  # processedContent - The String to be evaluated
  # Returns an object with the following fields
  #   moduleName - generated module name `angular.module('myApp')...`
  #   templateId - generated template id `$templateCache.put('id', ...)`
  #   templateContent - template content `$templateCache.put(..., <div>cache me!</div>')`
  evaluateTemplate = (processedContent, require=null) ->
    modules = {}

    context =
      # Mock for AngularJS $templateCache
      angular:
        module: (name, deps) ->
          if deps? then return modules[name] = new AngularModule name, deps
          if modules[name] then return modules[name]
          throw new Error "Module #{name} does not exists!"

    context.require = (require || sinon.stub()).callsArgWith(1, context.angular)

    vm.runInNewContext processedContent, context
    modules

  evaluateAngular2Template = (processedContent) ->
    mockWindow = {}
    context =
      window: mockWindow

    vm.runInNewContext processedContent, context
    mockWindow

  # Assert that require is used
  chai.Assertion.addMethod 'requireModule', (expectedModuleName) ->
    require = sinon.stub()

    code = utils.flag @, 'object'
    evaluateTemplate code, require

    sinon.assert.calledWith(require, [expectedModuleName])
    @

  # Assert that a module with the given name is defined
  chai.Assertion.addMethod 'defineModule', (expectedModuleName) ->
    code = utils.flag @, 'object'
    modules = evaluateTemplate code
    module = modules[expectedModuleName]
    definedModuleNames = (Object.keys modules).join ', '

    @assert module?,
      "expected to define module '#{expectedModuleName}' but only defined #{definedModuleNames}"

    utils.flag @, 'lastAssertedModule', module
    @

  # Assert that a template with the given id is defined
  chai.Assertion.addMethod 'defineTemplateId', (expectedTemplateId) ->
    # code = utils.flag @, 'object'
    # modules = evaluateTemplate code
    module = utils.flag @, 'lastAssertedModule'

    @assert module?,
      "you have to assert to.defineModule before asserting to.defineTemplateId"

    templateContent = module.templates[expectedTemplateId]
    definedTemplateIds = (Object.keys module.templates).join ', '

    @assert templateContent?,
      "expected to define template '#{expectedTemplateId}' but only defined #{definedTemplateIds}"

    utils.flag @, 'lastAssertedTemplateContent', templateContent
    @

  # Assert that a template with given id was defined in a Angular 2 template
  chai.Assertion.addMethod 'defineAngular2TemplateId', (expectedTemplateId) ->
    code = utils.flag @, 'object'
    mockWindow = evaluateAngular2Template code

    templateCache = mockWindow.$templateCache
    @assert templateCache?,
      "expected window.$templateCache to be defined but was not defined"

    templateContent = templateCache[expectedTemplateId]
    definedTemplateIds = (Object.keys templateCache).join ', '
    @assert templateContent?,
      "expected to define template '#{expectedTemplateId}' but only defined #{definedTemplateIds}"

    utils.flag @, 'lastAssertedTemplateContent', templateContent
    @

  # Assert that the cache has a valid content
  chai.Assertion.addMethod 'haveContent', (expectedContent) ->
    templateContent = utils.flag @, 'lastAssertedTemplateContent'

    @assert templateContent?,
      "you have to assert to.defineTemplateId or to.defineAngular2TemplateId " +
      "before asserting to.haveContent"

    @assert templateContent is expectedContent,
      "expected template content '#{templateContent}' to be '#{expectedContent}'"
