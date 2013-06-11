# Changelog

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
