# Changelog

## v0.0.1-beta.9 - 2013-07-15

* Adds support for glob patterns.

## v0.0.1-beta.8 - 2013-06-24

* Adds `year`, `month`, `day`, and `date` path variables.

## v0.0.1-beta.7 - 2013-06-24

* Drop support for running scripts in `post_scripts` directory. ‡
* Adds `scripts` option for clients' `parachute.json` which run the following
  recognized scripts: `preresolve`, `postresolve`, `preinstall`, and
  `postinstall`.

## v0.0.1-beta.6 - 2013-06-19

* Read __parachute.json__ instead of __assets.json__. ‡
* Revert `files` option back to `components` (since they don't all necessarily
  point to a single file). ‡

## v0.0.1-beta.5 - 2013-06-16

* New `files` option in _assets.json_.

* `dest` option in local JSON is now `root`. ‡
* `components` option in source JSON is now `files`. ‡

## v0.0.1-beta.4 - 2013-06-13

* Dependencies in _assets.json_ use `src` instead of `source`. ‡
* `components` array in source _assets.json_ use `src` and `dest` rather than
  `source` and `target`, respectively. ‡

## v0.0.1-beta.3 - 2013-06-13

* Fix data emission and progress output.
* Fix double update on install issue.

## v0.0.1-beta.2 - 2013-06-13

* `update` option for `Manager`.
* Prevent double cache attempt for dependencies already cached.

## v0.0.1-beta.1 - 2013-06-12

* New `Manager` class handles resolving, installing, and updating.
* Commands act somewhat like a proxy to respective `Manager` functions.
* Add Sinon to devDependencies, only being used in Manager tests at the moment.
* `Manager` and `Dependency` class architecture preps us for prime time.

## v0.0.1-alpha.5 - 2013-06-11

* Asset class renamed to Dependency.
* Fixes error throw issue for nonexistent sources in assets.json.

## v0.0.1-alpha.4 - 2013-06-07

* Components in `assets.json` can now handle single files. __NOTE:__ Directories
  must be suffixed with a forward slash `/` when specifying components.
* New lodash wrapper with extensions.
* New recursive copy utility, copycat.

## v0.0.1-alpha.3 - 2013-05-21

* `--update` option for `install` command updates repos before install.
* `help` takes specific commands with separate templates.
* Commands now have `--help` flags.
* `line` methods on commands to take command arguments.

## v0.0.1-alpha.2 - 2013-05-20

* Added update command to `git pull` dependencies.

‡ - Indicates breaking changes from previous versions.
