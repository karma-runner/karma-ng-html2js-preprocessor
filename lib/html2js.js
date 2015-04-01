var util = require('util');


var TEMPLATE = 'angular.module(\'%s\', []).run([\'$templateCache\', function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '}]);\n';

var SINGLE_MODULE_TPL = '(function(module) {\n' +
    'try {\n' +
    '  module = angular.module(\'%s\');\n' +
    '} catch (e) {\n' +
    '  module = angular.module(\'%s\', []);\n' +
    '}\n' +
    'module.run([\'$templateCache\', function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '}]);\n' +
    '})();\n';

var escapeContent = function(content) {
  return content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'');
};

var createHtml2JsPreprocessor = function(logger, basePath, config) {
  config = typeof config === 'object' ? config : {};

  var log = logger.create('preprocessor.html2js');
  var moduleName = config.moduleName;
  var stripPrefix = new RegExp('^' + (config.stripPrefix || ''));
  var prependPrefix = config.prependPrefix || '';
  var stripSufix = new RegExp((config.stripSufix || '') + '$');
  var cacheIdFromPath = config && config.cacheIdFromPath || function(filepath) {
    return prependPrefix + filepath.replace(stripPrefix, '').replace(stripSufix, '');
  };

  return function(content, file, done) {
    log.debug('Processing "%s".', file.originalPath);

    var relativeTemplatePath = file.originalPath.replace(basePath + '/', '');
    var htmlPath = cacheIdFromPath(relativeTemplatePath);
    var customModuleName;

    if (!/\.js$/.test(file.path)) {
      file.path = file.path + '.js';
    }

    if (moduleName) {
      if (typeof moduleName === 'string') {
        customModuleName = moduleName;
      } else if(typeof moduleName === 'function') {
        customModuleName = moduleName(relativeTemplatePath);
      }
      done(util.format(SINGLE_MODULE_TPL, customModuleName, customModuleName, htmlPath, escapeContent(content)));
    } else {
      done(util.format(TEMPLATE, htmlPath, htmlPath, escapeContent(content)));
    }
  };
};

createHtml2JsPreprocessor.$inject = ['logger', 'config.basePath', 'config.ngHtml2JsPreprocessor'];

module.exports = createHtml2JsPreprocessor;
