fs = require 'fs'
url = require 'url'
path = require 'path'

PORT = 3000
MODE = 'dist'
INDEX = 'index.html'

args = [].concat process.argv
while arg = args.shift()
  switch arg
    when '-p', '--port'
      PORT = parseInt args.shift()
    when '-m', '--mode'
      MODE = args.shift()
      MODE = if MODE is 'dev' then 'dist' else 'public'
    when '-i', '--index'
      INDEX = args.shift()
      INDEX = INDEX.slice 1 while '/' is INDEX.slice 0, 1
    when '-h', '--help'
      console.log '''
        Usage: grunt [options]

        Options:
          -p, --port  [INT]  server port (3000)
          -m, --mode  [STR]  "dev" or "pro" (dev)
          -i, --index [STR]  fallback file (index.html)
          -h, --help         show this message and exit

        Example:
          grunt -p 3000 -m dev -i index.html

        Tasks:
          Build:
            coffee, stylus, jade
          Lint:
            jshint, csslint
          Minify:
            uglify, cssmin, htmlmin
          Server:
            connect, watch
          Phony:
            default - launch server after build
            build   - execute all tasks without server
        '''
      process.exit 1

index = path.resolve MODE, INDEX

module.exports = (grunt) ->
  grunt.initConfig

    pkg: grunt.file.readJSON 'package.json'

    coffee:
      options:
        sourceMap: yes
      compile:
        files: [{
          expand: yes
          cwd: 'assets/'
          src: [ '**/*.coffee' ]
          dest: 'dist/'
          ext: '.js'
        }]

    stylus:
      options:
        compress: no
      compile:
        files: [{
          expand: yes
          cwd: 'assets/'
          src: [ '**/*.styl' ]
          dest: 'dist/'
          ext: '.css'
        }]

    jade:
      options:
        pretty: yes
      compile:
        files: [{
          expand: yes
          cwd: 'assets/'
          src: [ '**/*.jade' ]
          dest: 'dist/'
          ext: '.html'
        }]

    jshint:
      options:
        jshintrc: '.jshintrc'
      files: 'dist/**/*.js'

    csslint:
      options:
        csslintrc: '.csslintrc'
      strict:
        options:
          import: 2
        src: 'dist/**/*.css'

    uglify:
      minify:
        files: [{
          expand: yes
          cwd: 'dist/'
          src: [ '**/*.js' ]
          dest: 'public/'
          ext: '.js'
        }]

    cssmin:
      minify:
        files: [{
          expand: yes
          cwd: 'dist/'
          src: [ '**/*.css' ]
          dest: 'public/'
          ext: '.css'
        }]

    htmlmin:
      minify:
        files: [{
          expand: yes
          cwd: 'dist/'
          src: [ '**/*.html' ]
          dest: 'public/'
          ext: '.html'
        }]

    watch:
      options:
        livereload: yes
        dateFormat: (time) ->
          grunt.log.writeln "The watch finished in #{time}ms at #{new Date().toLocaleTimeString()}"
      coffee:
        files: ['assets/**/*.coffee']
        tasks: ['coffee', 'uglify']
      jade:
        files: ['assets/*.jade']
        tasks: ['jade']
      stylus:
        files: ['assets/**/*.styl']
        tasks: ['stylus', 'cssmin']

    connect:
      server:
        options:
          port: PORT
          middleware: (connect, options) ->
            mw = [connect.logger 'dev']
            mw.push (req, res) ->
              route = path.resolve MODE, (url.parse req.url).pathname.replace /^\//, ''
              fs.exists route, (exist) ->
                fs.stat route, (err, stat) ->
                  return fs.createReadStream(route).pipe(res) if exist and stat.isFile()
                  return fs.createReadStream(index).pipe(res)
            return mw

  # compile
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  # lint
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-csslint'
  # minify
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-htmlmin'
  # server
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'build', [
    'coffee', 'jshint', 'uglify'
    'stylus', 'csslint', 'cssmin'
    'jade', 'htmlmin'
  ]
  grunt.registerTask 'default', ['build', 'connect', 'watch']
