vm = require('vm')

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
  # useRequire - Use a fake require.js
  # Returns an object with the following fields
  #   moduleName - generated module name `angular.module('myApp')...`
  #   templateId - generated template id `$templateCache.put('id', ...)`
  #   templateContent - template content `$templateCache.put(..., <div>cache me!</div>')`
  evaluateTemplate = (processedContent, useRequire = false) ->
    modules = {}

    context =
      # Mock for AngularJS $templateCache
      angular:
        module: (name, deps) ->
          if deps? then return modules[name] = new AngularModule name, deps
          if modules[name] then return modules[name]
          throw new Error "Module #{name} does not exists!"

    if useRequire
      context.require = (deps, fn) -> fn context.angular

    vm.runInNewContext processedContent, context
    modules

  # Assert that a module with the given name is defined
  chai.Assertion.addMethod 'defineModule', (expectedModuleName, useRequireJs = false) ->
    code = utils.flag @, 'object'
    modules = evaluateTemplate code, useRequireJs
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

  # Assert that the cache has a valid content
  chai.Assertion.addMethod 'haveContent', (expectedContent) ->
    templateContent = utils.flag @, 'lastAssertedTemplateContent'

    @assert templateContent?,
      "you have to assert to.defineTemplateId before asserting to.haveContent"

    @assert templateContent is expectedContent,
      "expected template content '#{templateContent}' to be '#{expectedContent}'"
