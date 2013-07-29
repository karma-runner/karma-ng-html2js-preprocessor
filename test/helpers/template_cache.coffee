vm = require('vm')

module.exports = (chai, utils) ->

  # Evaluates generated js code fot the template cache
  # processedContent - The String to be evaluated
  # Returns an object with the following fields
  #   moduleName - generated module name `angular.module('myApp')...`
  #   templateId - generated template id `$templateCache.put('id', ...)`
  #   templateContent - template content `$templateCache.put(..., <div>cache me!</div>')`
  evaluateTemplate = (processedContent) ->
    result = {}

    sandbox =
      # Mock for AngularJS $templateCache
      angular:
        module: (name, deps = []) ->
          result.moduleName = name

          run: (block) ->
            block
              put: (id, content) ->
                result.templateId = id
                result.templateContent = content

    context = vm.createContext(sandbox)
    vm.runInContext(processedContent, context, 'foo.vm')

    result

  # Assert that a module with the given name is defined
  chai.Assertion.addMethod 'defineModule', (expected) ->
    template = utils.flag(this, 'object')
    actualName = evaluateTemplate(template).moduleName

    @assert actualName is expected,
      "expected defined module name '#{actualName}' to be '#{expected}'"

  # Assert that a template with the given id is defined
  chai.Assertion.addMethod 'defineTemplateId', (expected) ->
    template = utils.flag(this, 'object')
    actualId = evaluateTemplate(template).templateId

    @assert actualId is expected,
      "expected defined template id '#{actualId}' to be '#{expected}'"

  # Assert that the cache has a valid content
  chai.Assertion.addMethod 'haveContent', (expected) ->
    template = utils.flag(this, 'object')
    actualContent = evaluateTemplate(template).templateContent

    @assert actualContent is expected,
      "expected template content '#{actualContent}' to be '#{expected}'"
