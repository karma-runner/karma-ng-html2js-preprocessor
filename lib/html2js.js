var util = require('util');


var TEMPLATE = 'angular.module(\'%s\', []).run(function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '});\n';

var SINGLE_MODULE_TPL = '(function(moduleName, htmlPath, contents) {\n' +
    'var module;\n' +
    'try {\n' +
    '  module = angular.module(moduleName);\n' +
    '} catch (e) {\n' +
    '  module = angular.module(moduleName, []);\n' +
    '}\n' +
    'module.run(function($templateCache) {\n' +
    '  $templateCache.put(htmlPath, contents);\n' +
    '});\n' +
    '})(\'%s\', \'%s\', \'%s\');\n';

var escapeContent = function(content) {
  return content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'');
};

var createHtml2JsPreprocessor = function(logger, basePath, config) {
  config = typeof config === 'object' ? config : {};

  var log = logger.create('preprocessor.html2js');
  var moduleName = config.moduleName;
  var requireDeps = config.requireDeps;
  var stripPrefix = new RegExp('^' + (config.stripPrefix || ''));
  var prependPrefix = config.prependPrefix || '';
  var cacheIdFromPath = config && config.cacheIdFromPath || function(filepath) {
    return prependPrefix + filepath.replace(stripPrefix, '');
  };

  return function(content, file, done) {
    log.debug('Processing "%s".', file.originalPath);

    var htmlPath = cacheIdFromPath(file.originalPath.replace(basePath + '/', ''));

    file.path = file.path + '.js';

    if (moduleName) {
      var script = util.format(SINGLE_MODULE_TPL, moduleName, htmlPath, escapeContent(content));
      if(requireDeps && requireDeps instanceof Array) {
        script = 'require([\'' +
                  requireDeps.join('\', \'') +
                  '\'],\n function(' +
                  requireDeps.join(', ') +
                  ') {\n' + script + '\n})';
      }
      done(script);
    } else {
      done(util.format(TEMPLATE, htmlPath, htmlPath, escapeContent(content)));
    }
  };
};

createHtml2JsPreprocessor.$inject = ['logger', 'config.basePath', 'config.ngHtml2JsPreprocessor'];

module.exports = createHtml2JsPreprocessor;
