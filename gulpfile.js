var gulp   = require('gulp');
var jshint = require('gulp-jshint');

gulp.task('lint', function() {
  gulp.src(['lib/*.js', 'test/*.js'])
    .pipe(jshint())
    .pipe(jshint.reporter('jshint-stylish'));
});

gulp.task('watch', function() {
  gulp.watch(['lib/*.js', 'test/*.js'], ['lint']);
});

gulp.task('default', ['watch']);
