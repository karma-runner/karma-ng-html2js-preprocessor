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

function extend(target) {
  var sources = [].slice.call(arguments, 1);
  for (var i=0; i<sources.length; i++) {
    var src = sources[i];
    for (var prop in src) {
      target[prop] = src[prop];
    }
  }
  return target;
}

function createOptions(customConfig, baseConfig) {
  // Ignore 'base' property of custom preprocessor's config.
  customConfig = extend({}, customConfig);
  delete customConfig.base;

  var options = extend(baseConfig || {}, customConfig || {});
  return options;
}

var createHtml2JsPreprocessor = function(logger, basePath, config, args) {
  config = typeof config === 'object' ? config : {};

  var options = createOptions(args, config);

  var log = logger.create('preprocessor.html2js');
  var moduleName = options.moduleName;
  var stripPrefix = new RegExp('^' + (options.stripPrefix || ''));
  var prependPrefix = options.prependPrefix || '';
  var stripSufix = new RegExp((options.stripSufix || '') + '$');
  var cacheIdFromPath = options && options.cacheIdFromPath || function(filepath) {
        return prependPrefix + filepath.replace(stripPrefix, '').replace(stripSufix, '');
      };

  return function(content, file, done) {
    log.debug('Processing "%s".', file.originalPath);

    var htmlPath = cacheIdFromPath(file.originalPath.replace(basePath + '/', ''));

    if (!/\.js$/.test(file.path)) {
      file.path = file.path + '.js';
    }

    if (moduleName) {
      done(util.format(SINGLE_MODULE_TPL, moduleName, moduleName, htmlPath, escapeContent(content)));
    } else {
      done(util.format(TEMPLATE, htmlPath, htmlPath, escapeContent(content)));
    }
  };
};

createHtml2JsPreprocessor.$inject = ['logger', 'config.basePath', 'config.ngHtml2JsPreprocessor', 'args'];

module.exports = createHtml2JsPreprocessor;
