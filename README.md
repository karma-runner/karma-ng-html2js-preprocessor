# karma-ng-html2js-preprocessor

[![js-standard-style](https://img.shields.io/badge/code%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/karma-runner/karma-ng-html2js-preprocessor)
 [![npm version](https://img.shields.io/npm/v/karma-ng-html2js-preprocessor.svg?style=flat-square)](https://www.npmjs.com/package/karma-ng-html2js-preprocessor) [![npm downloads](https://img.shields.io/npm/dm/karma-ng-html2js-preprocessor.svg?style=flat-square)](https://www.npmjs.com/package/karma-ng-html2js-preprocessor)

[![Build Status](https://img.shields.io/travis/karma-runner/karma-ng-html2js-preprocessor/master.svg?style=flat-square)](https://travis-ci.org/karma-runner/karma-ng-html2js-preprocessor) [![Dependency Status](https://img.shields.io/david/karma-runner/karma-ng-html2js-preprocessor.svg?style=flat-square)](https://david-dm.org/karma-runner/karma-ng-html2js-preprocessor) [![devDependency Status](https://img.shields.io/david/dev/karma-runner/karma-ng-html2js-preprocessor.svg?style=flat-square)](https://david-dm.org/karma-runner/karma-ng-html2js-preprocessor#info=devDependencies)

> Preprocessor for converting HTML files to [AngularJS 1.x](http://angularjs.org/) templates.

*Note:* If you are looking for a general preprocessor that is not tied to Angular, check out [karma-html2js-preprocessor](https://github.com/karma-runner/karma-html2js-preprocessor).

*Note:* If you are using Angular 2.x, use [karma-redirect-preprocessor](https://github.com/sjelin/karma-redirect-preprocessor).

## Installation

The easiest way is to keep `karma-ng-html2js-preprocessor` as a devDependency in your `package.json`. Just run

```bash
$ npm install karma-ng-html2js-preprocessor --save-dev
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

    // if you have defined plugins explicitly, add karma-ng-html2js-preprocessor
    // plugins: [
    //     <your plugins>
    //     'karma-ng-html2js-preprocessor',
    // ]

    ngHtml2JsPreprocessor: {
      // strip this from the file path
      stripPrefix: 'public/',
      stripSuffix: '.ext',
      // prepend this to the
      prependPrefix: 'served/',

      // or define a custom transform function
      // - cacheId returned is used to load template
      //   module(cacheId) will return template at filepath
      cacheIdFromPath: function(filepath) {
        // example strips 'public/' from anywhere in the path
        // module(app/templates/template.html) => app/public/templates/template.html
        var cacheId = filepath.strip('public/', '');
        return cacheId;
      },

      // - setting this option will create only a single module that contains templates
      //   from all the files, so you can load them all with module('foo')
      // - you may provide a function(htmlPath, originalPath) instead of a string
      //   if you'd like to generate modules dynamically
      //   htmlPath is a originalPath stripped and/or prepended
      //   with all provided suffixes and prefixes
      moduleName: 'foo'
    }
  })
}
```

### Multiple module names

Use *function* if more than one module that contains templates is required.

```js
// karma.conf.js
module.exports = function(config) {
  config.set({
    // ...

    ngHtml2JsPreprocessor: {
      // ...

      moduleName: function (htmlPath, originalPath) {
        return htmlPath.split('/')[0];
      }
    }
  })
}
```

If only some of the templates should be placed in the modules,
return `''`, `null` or `undefined` for those which should not.

```js
// karma.conf.js
module.exports = function(config) {
  config.set({
    // ...

    ngHtml2JsPreprocessor: {
      // ...

      moduleName: function (htmlPath, originalPath) {
        var module = htmlPath.split('/')[0];
        return module !== 'tpl' ? module : null;
      }
    }
  })
}
```


## How does it work ?

This preprocessor converts HTML files into JS strings and generates Angular modules. These modules, when loaded, puts these HTML files into the `$templateCache` and therefore Angular won't try to fetch them from the server.

For instance this `template.html`...
```html
<div>something</div>
```
... will be served as `template.html.js`:
```js
angular.module('template.html', []).run(function($templateCache) {
  $templateCache.put('template.html', '<div>something</div>')
})
```

See the [ng-directive-testing](https://github.com/vojtajina/ng-directive-testing) for a complete example.

----

For more information on Karma see the [homepage].


[homepage]: http://karma-runner.github.com
