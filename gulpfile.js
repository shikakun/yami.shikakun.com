var autoprefixer    = require('gulp-autoprefixer');
var concat          = require('gulp-concat');
var csso            = require('gulp-csso');
var gulp            = require('gulp');
var imagemin        = require('gulp-imagemin');
var jpegRecompress  = require('imagemin-jpeg-recompress');
var plumber         = require('gulp-plumber');
var pngquant        = require('imagemin-pngquant');
var runSequence     = require('run-sequence');
var sass            = require('gulp-sass');
var uglify          = require('gulp-uglify');
var watch           = require('gulp-watch');

var config = {
  'dir': {
    'dist': 'public',
    'src' : 'assets'
  }
}

gulp.task('build:style', function() {
  return gulp.src(config.dir.src + '/styles/style.scss')
    .pipe(plumber())
    .pipe(sass())
    .pipe(autoprefixer({
      browser: [
        'last 2 version'
      ]
    }))
    .pipe(csso())
    .pipe(gulp.dest(config.dir.dist));
});

gulp.task('build:script', function() {
  return gulp.src([config.dir.src + '/scripts/vendor/**/*.js', config.dir.src + '/scripts/**/*.js'])
    .pipe(plumber())
    .pipe(concat('script.js'))
    .pipe(uglify({
      preserveComments: 'some'
    }))
    .pipe(gulp.dest(config.dir.dist));
});

gulp.task('build:image', function() {
  return gulp.src(config.dir.src + '/images/**/*.{png,jpg,gif,svg}')
    .pipe(imagemin({
      optimizationLevel: 7,
      use: [
        pngquant({
          quality: '60-80',
          speed: 1
        }),
        jpegRecompress()
      ]
    }))
    .pipe(gulp.dest(config.dir.dist + '/images'));
});

gulp.task('build', function(callback) {
  runSequence('build:style', 'build:script', 'build:image', callback);
});

gulp.task('default', function() {
  gulp.start('build');
  gulp.watch(config.dir.src + '/styles/**/*.scss', ['build:style']);
  gulp.watch(config.dir.src + '/scripts/**/*.js', ['build:script']);
  gulp.watch(config.dir.src + '/images/**/*.{png,jpg,gif,svg}', ['build:image']);
});
