module.exports = (grunt) ->
  grunt.initConfig
    pkgFile: 'package.json'

    files:
      source: ['lib/**/*.js']

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'dot'
      unit:
        src: [
          # 'test/mocha-common.js'
          'test/**/*.coffee'
        ]

    # JSHint options
    # http://www.jshint.com/options/
    jshint:
      source:
        files:
          src: '<%= files.source %>'
        options:
          node: true,
          es5: true,
          strict: false

      options:
        quotmark: 'single'
        camelcase: true
        strict: true
        trailing: true
        curly: true
        eqeqeq: true
        immed: true
        latedef: true
        newcap: true
        noarg: true
        sub: true
        undef: true
        boss: true
        globals: {}

    bump:
      options:
        commitMessage: 'chore: release v%VERSION%'
        pushTo: 'upstream'

  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-npm'
  grunt.loadNpmTasks 'grunt-bump'

  grunt.registerTask 'default', ['jshint', 'test']
  grunt.registerTask 'test', ['simplemocha:unit']
  grunt.registerTask 'release', 'Build, bump and publish to NPM.', (type) ->
    grunt.task.run [
      "bump:#{type||'patch'}",
      'npm-publish'
    ]
