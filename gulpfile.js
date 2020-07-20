var gulp = require('gulp');
var babel = require('gulp-babel')
var concat = require('gulp-concat');
var rename = require('gulp-rename');
gulp.remote = require('gulp-remote');

var target = ['./www/_NativeVideoPlayer.js'];
var output = './www';



// js file babel
gulp.task('babel', function() {
  var babelSettings = {presets: ['@babel/env']}
  return gulp.src(target)
    .pipe(babel(babelSettings))
    .pipe(rename('NativeVideoPlayer.js'))
    .pipe(gulp.dest(output));
})

// watch
gulp.task('watch', function(){
  gulp.watch(target, gulp.task('babel'));
});


gulp.task('default', gulp.series( gulp.parallel('babel')));