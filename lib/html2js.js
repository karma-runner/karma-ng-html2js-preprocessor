var util = require('util');

var TEMPLATE = 'angular.module(\'%s\', []).run(function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '});\n';

var SINGLE_MODULE_TPL_START = '(function(module) {\n' +
    'try {\n' +
    '  module = angular.module(\'%s\');\n' +
    '} catch (e) {\n' +
    '  module = angular.module(\'%s\', []);\n' +
    '}\n';
var SINGLE_MODULE_TPL = 'module.run(function($templateCache) {\n' +
    '  $templateCache.put(\'%s\',\n    \'%s\');\n' +
    '});\n';
var SINGLE_MODULE_TPL_END = '})();\n';

// Regular Expressions that match <script type="text/ng-template" id="templateId">...</script>
var SCRIPT_RES = [
  new RegExp('<script[^>]*?\\bid="([^"]+)"[^>]*?\\btype="text/ng-template"[^>]*?>((.|\\n)*?)</script>', 'im'),
  new RegExp('<script[^>]*?\\btype="text/ng-template"[^>]*?\\bid="([^"]+)"[^>]*?>((.|\\n)*?)</script>', 'im')
];

var escapeContent = function(content) {
  return content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'');
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

    file.path = file.path + '.js';

    var templates = [];

    // Strip out ng-template stuff here...
    for (var i = 0; i < SCRIPT_RES.length; i++) {
      var re = SCRIPT_RES[i];
      var match;
      while (match = content.match(re)) {
        templates.push([match[1], match[2]]);
        content = content.replace(re, '');
      }
    }

    if (content.trim()) {
      templates.push([htmlPath, content]);
    }


    for (i = 0; i < templates.length; i++) {
      htmlPath = templates[i][0];
      content = templates[i][1];
      if (moduleName) {
        templates[i] = util.format(SINGLE_MODULE_TPL, htmlPath, escapeContent(content));
      } else {
        templates[i] = util.format(TEMPLATE, htmlPath, htmlPath, escapeContent(content));
      }
    }
    if (moduleName) {
      done(util.format(SINGLE_MODULE_TPL_START, moduleName, moduleName) +
           templates.join('\n') +
           SINGLE_MODULE_TPL_END);

    } else {
      done(templates.join('\n'));
    }
  };
};

createHtml2JsPreprocessor.$inject = ['logger', 'config.basePath', 'config.ngHtml2JsPreprocessor'];

module.exports = createHtml2JsPreprocessor;
