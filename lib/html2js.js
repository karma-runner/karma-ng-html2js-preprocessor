var util = require('util');


var TEMPLATE = 'angular.module(\'%s\', []).run(function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '});\n';

var SINGLE_MODULE_TPL = '(function(module) {\n' +
    'try {\n' +
    '  module = angular.module(\'%s\');\n' +
    '} catch (e) {\n' +
    '  module = angular.module(\'%s\', []);\n' +
    '}\n' +
    'module.run(function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '});\n' +
    '})();\n';

var escapeContent = function(content) {
  return content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'');
};

/**
 * transform the served file path.
 * 
 * @param {String} path - the served file path
 * @param {Object} config - the transform config
 * 
 * @return {String} return the transformed file path.
 */
var transformPath = function(path, config) {
    var reg, replacement;
    if (typeof config === 'object') {
      reg = new RegExp(config.pattern || '');
      replacement = config.replacement;
      path = path.replace(reg, replacement) + '.js';
    } else if (typeof config === 'function') {
      path = config(path);
    } else {
      path = path + '.js';
    }
    return path;
};

var createHtml2JsPreprocessor = function(logger, basePath, config) {
  config = typeof config === 'object' ? config : {};

  var log = logger.create('preprocessor.html2js');
  var moduleName = config.moduleName;
  var stripPrefix = new RegExp('^' + (config.stripPrefix || ''));
  var prependPrefix = config.prependPrefix || '';
  var cacheIdFromPath = config && config.cacheIdFromPath || function(filepath) {
    return prependPrefix + filepath.replace(stripPrefix, '');
  };

  return function(content, file, done) {
    log.debug('Processing "%s".', file.originalPath);

    var htmlPath = cacheIdFromPath(file.originalPath.replace(basePath + '/', ''));

    file.path = transformPath(file.path, config.transformPath);

    if (moduleName) {
      done(util.format(SINGLE_MODULE_TPL, moduleName, moduleName, htmlPath, escapeContent(content)));
    } else {
      done(util.format(TEMPLATE, htmlPath, htmlPath, escapeContent(content)));
    }
  };
};

createHtml2JsPreprocessor.$inject = ['logger', 'config.basePath', 'config.ngHtml2JsPreprocessor'];

module.exports = createHtml2JsPreprocessor;
