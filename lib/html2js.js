var util = require('util');


var TEMPLATE = 'angular.module(\'%s\', []).run(function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '});\n';

var TEMPLATE_REQUIRE =
    'require([\'%s\'], function(angular) {\n' +
    '  angular.module(\'%s\', []).run(function($templateCache) {\n' +
    '    $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '  });\n' +
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

var SINGLE_MODULE_REQUIRE_TPL =
    'require([\'%s\'], function(angular) {\n' +
    '  var module;\n' +
    '  try {\n' +
    '    module = angular.module(\'%s\');\n' +
    '  } catch (e) {\n' +
    '    module = angular.module(\'%s\', []);\n' +
    '  }\n' +
    '  module.run(function($templateCache) {\n' +
    '    $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '  });\n' +
    '});\n';


var escapeContent = function(content) {
  return content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'');
};

var createHtml2JsPreprocessor = function(logger, basePath, config, frameworks) {
  config = typeof config === 'object' ? config : {};

  var log = logger.create('preprocessor.html2js');
  var moduleName = config.moduleName;
  var stripPrefix = new RegExp('^' + (config.stripPrefix || ''));
  var prependPrefix = config.prependPrefix || '';
  var stripSufix = new RegExp((config.stripSufix || '') + '$');
  var cacheIdFromPath = config && config.cacheIdFromPath || function(filepath) {
    return prependPrefix + filepath.replace(stripPrefix, '').replace(stripSufix, '');
  };

  // require.js additions
  var useRequire = frameworks && frameworks.indexOf('requirejs') !== -1 || Boolean(config.require);
  var angularShim = config.require && config.require.angularShim || 'angular';

  return function(content, file, done) {
    log.debug('Processing "%s".', file.originalPath);

    var htmlPath = cacheIdFromPath(file.originalPath.replace(basePath + '/', ''));

    if (useRequire) {
      file.path = basePath + '/' + htmlPath.replace(/\//g, '-');
    }

    if (!/\.js$/.test(file.path)) {
      file.path = file.path + '.js';
    }

    if (moduleName) {
      if (useRequire) {
        done(util.format(SINGLE_MODULE_REQUIRE_TPL, angularShim, moduleName, moduleName, htmlPath, escapeContent(content)));
      } else {
        done(util.format(SINGLE_MODULE_TPL, moduleName, moduleName, htmlPath, escapeContent(content)));
      }
    } else {
      if (useRequire) {
        done(util.format(TEMPLATE_REQUIRE, angularShim, htmlPath, htmlPath, escapeContent(content)));
      } else {
        done(util.format(TEMPLATE, htmlPath, htmlPath, escapeContent(content)));
      }
    }
  };
};

createHtml2JsPreprocessor.$inject = ['logger', 'config.basePath', 'config.ngHtml2JsPreprocessor', 'config.frameworks'];

module.exports = createHtml2JsPreprocessor;
