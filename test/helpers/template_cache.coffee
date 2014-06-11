vm = require('vm')

module.exports = (chai, utils) ->

  class AngularModule
    constructor: (@name, @deps) ->
      templates = @templates = {}

    run: (block) ->
      block
        put: (id, content) =>
          @templates[id] = content


  # Evaluates generated js code for the template cache
  # processedContent - The String to be evaluated
  # Returns an object with the following fields
  #   moduleName - generated module name `angular.module('myApp')...`
  #   templateId - generated template id `$templateCache.put('id', ...)`
  #   templateContent - template content `$templateCache.put(..., <div>cache me!</div>')`
  evaluateTemplate = (processedContent) ->
    modules = {}

    context =
      # Mock for AngularJS $templateCache
      angular:
        module: (name, deps) ->
          if deps? then return modules[name] = new AngularModule name, deps
          if modules[name] then return modules[name]
          throw new Error "Module #{name} does not exists!"

    vm.runInNewContext processedContent, context
    modules

  # Evaluates generated js code (with requirejs template) for the template cache
  # processedContent - The String to be evaluated
  # Returns an object with the following fields
  #   dependencies - array of dependencies required by the require.js wrapper
  #   dependencyVars - the variables mapped to the dependency array
  #   module - a string that represents the module code.       
  evaluateRequireJsTemplate = (processedContent) ->
    info = {}

    context =
      # Mock for RequireJS wrapper
      require: (deps, module) ->
        info.dependencies = deps 
        info.dependencyVars = getFunctionParams module
        info.module = '(' + module.toString() + ')()';

    vm.runInNewContext processedContent, context
    info

  # Helper function that retrieves the arguments of a function.
  getFunctionParams = (func) ->
    STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg;
    ARGUMENT_NAMES = /([^\s,]+)/g;
    fnStr = func.toString()
                .replace STRIP_COMMENTS, ''
    startIndex = fnStr.indexOf '('
    endIndex = fnStr.indexOf ')'
    result = fnStr.slice startIndex + 1, endIndex
    result = result.match ARGUMENT_NAMES
    if not result? then result = []
    result

  # Assert that a requirejs wrapper is defined
  chai.Assertion.addMethod 'defineRequireJsWrapper', (expectedDependencies) ->
    code = utils.flag @, 'object'
    info = evaluateRequireJsTemplate code
    expectedDependenciesStr = expectedDependencies.join ','
    dependenciesStr = info.dependencies.join ','
    dependencyVarsStr = info.dependencyVars.join ','

    @assert dependenciesStr is dependencyVarsStr,
      "expected dependency arguments of the wrapper '#{dependencyVarsStr}' to match module dependencies '#{dependenciesStr}'"

    @assert dependenciesStr is expectedDependenciesStr,
      "expected module dependencies '#{dependenciesStr}' to be '#{expectedDependenciesStr}'"

    utils.flag @, 'object', info.module
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

  # Assert that the cache has a valid content
  chai.Assertion.addMethod 'haveContent', (expectedContent) ->
    templateContent = utils.flag @, 'lastAssertedTemplateContent'

    @assert templateContent?,
      "you have to assert to.defineTemplateId before asserting to.haveContent"

    @assert templateContent is expectedContent,
      "expected template content '#{templateContent}' to be '#{expectedContent}'"
