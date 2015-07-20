'use strict';

module.exports = function(grunt) {
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    // grunt-contrib-connectの設定(Webサーバの設定)
    connect: {
      site: { // オプション未設定の為、空オブジェクト
      }
    },
    coffee: {
      options: {
        bare: true, // 名前空間を汚さないようにする機能をOFF
        sourceMap: true
      },
      glob_to_multiple: {
        expand: true,
        cwd: 'public/coffee/',
        src: ['*.coffee'],
        dest: 'public/js/',
        ext:  '.js',
      }
    },

    // grunt-contrib-watchの設定(ウォッチ対象の設定)
    watch: {
      html_files: {
        files: ['views/*'] // ウォッチ対象として、ディレクトリ配下の*.htmlを指定
      },
      coffee: {
          files: ['public/coffee/*.coffee'],
          tasks: ['coffee'],
      },
      css: {
          files: ['view/*.css']
      },
      options: {
        livereload: true // 変更があればリロードするよ
      }
    },
    // init build
    build: {
      coffee: {
          files: ['public/coffee/*.coffee'],
          tasks: ['coffee'],
        }
    }
  });

  // Load tasks(grunt実行時に読み込むプラグイン)
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-coffee');

  // Default tasks(grunt実行時に実行するタスク)
  grunt.registerTask('default', ['connect', 'watch']);
  grunt.registerTask('build', ['coffee']);
};
