# karma-ng-html2js-preprocessor [![Build Status](https://travis-ci.org/karma-runner/karma-ng-html2js-preprocessor.svg?branch=master)](https://travis-ci.org/karma-runner/karma-ng-html2js-preprocessor)

> Preprocessor for converting HTML files to [AngularJS](http://angularjs.org/) templates.

*Note:* If you are looking for a general preprocessor that is not tied to Angular, check out [karma-html2js-preprocessor](https://github.com/karma-runner/karma-html2js-preprocessor).

## Installation

The easiest way is to keep `karma-ng-html2js-preprocessor` as a devDependency in your `package.json`.
```json
{
  "devDependencies": {
    "karma": "~0.10",
    "karma-ng-html2js-preprocessor": "~0.1"
  }
}
```

You can simple do it by:
```bash
npm install karma-ng-html2js-preprocessor --save-dev
```

## Configuration
```js
// karma.conf.js
module.exports = function(config) {
  config.set({
    preprocessors: {
      '**/*.html': ['ng-html2js']
    },

    files: [
      '*.js',
      '*.html',
      '*.html.ext',
      // if you wanna load template files in nested directories, you must use this
      '**/*.html'
    ],

    ngHtml2JsPreprocessor: {
      // strip this from the file path
      stripPrefix: 'public/',
      stripSufix: '.ext',
      // prepend this to the
      prependPrefix: 'served/',

      // or define a custom transform function
      cacheIdFromPath: function(filepath) {
        return cacheId;
      },

      // setting this option will create only a single module that contains templates
      // from all the files, so you can load them all with module('foo')
      moduleName: 'foo',
      // setting this option will use require.js to wrap the preprocessed templates
      // if karma.frameworks contains 'requirejs' you only need to specify this
      // option set if you are using non-default values
      require: {
        // the name of the angular shim, defaults to angular
        angularShim: 'angular'
      }
    }
  });
};
```

## How does it work ?

This preprocessor converts HTML files into JS strings and generates Angular modules. These modules, when loaded, puts these HTML files into the `$templateCache` and therefore Angular won't try to fetch them from the server.

For instance this `template.html`...
```html
<div>something</div>
```
... will be served as `template.html.js`:
```js
angular.module('template.html', []).config(function($templateCache) {
  $templateCache.put('template.html', '<div>something</div>');
});
```

See the [ng-directive-testing](https://github.com/vojtajina/ng-directive-testing) for a complete example.

----

The dependencies for the test-main.js file should be modified according to the code example below to properly load the templates as requirements for the test.

```js
var dependencies = [];

var DEP_REGEXP = /(Spec|\.html)\.js$/;

var pathToModule = function(path) {
    return path.replace(/^\/base\//, '').replace(/\.js$/, '');
};

Object.keys(window.__karma__.files).forEach(function(file) {
    if (DEP_REGEXP.test(file)) {
        // Normalize paths to RequireJS module names.
        dependencies.push(pathToModule(file));
    }
});
```

----

For more information on Karma see the [homepage].


[homepage]: http://karma-runner.github.com
