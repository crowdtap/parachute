var gulp   = require('gulp');
var jshint = require('gulp-jshint');

var scripts = [
  'lib/**/*.js',
  'test/**/*.js',
  'bin/**',
  '!test/{tmp|tmp/**}'
];

gulp.task('lint', function() {
  gulp.src(scripts)
    .pipe(jshint())
    .pipe(jshint.reporter('jshint-stylish'));
});

gulp.task('watch', function() {
  gulp.watch(scripts, ['lint']);
});

gulp.task('default', ['watch']);
