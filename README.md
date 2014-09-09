# Parachute [![Build Status](https://travis-ci.org/crowdtap/parachute.png)](https://travis-ci.org/crowdtap/parachute)

A simple utility for managing shared assets across many applications.

Requires Node >=0.10 and Git >=1.8.5

__Below are the docs for v0.x.x.__

__v1.x.x docs are still a work in progress. Feel free to check out the tests for examples.__

## Installation

Parachute is a [Node](http://nodejs.org/) module available through
[npm](https://npmjs.org/). To install it globally, run:

```bash
npm install parachute -g
```

Alternatively, you can add it to your project's `package.json` under _devDependencies_:

```bash
"devDependencies": {
  "parachute": "latest"
}
```

## Configuration

Assets should be hosted in a git repository, either locally or more commonly, in a remote repository. 

### Client

Dependencies are listed in `parachute.json`, and have the following options:

* `src` - Relative path for local git repository directory, or URL to remote repository. [Required]
* `root` - Root directory for files copied on install. Destinations dictated by a host's `components` option or a client dependency's `files` option are relative to this value. [Default: current working directory]
* `files` - Array of specific files to copy from host. Array elements can either be a string of the filename (which gets copied into the `root` folder) or an object with a `src` and `dest` property.

Client options:

* `scripts` - Commands to execute at predefined points in the install process.
  The following are recognized: `preresolve`, `postresolve`, `preinstall`, and
  `postinstall`.

* __Treeish__ - Dependencies can point to a specific commit or branch using the following example syntax: `git@github.com:crowdtap/assets.shared.git#some-branch`.

Example:

```javascript
{
  "dependencies": [
    {
      "src": "../local-shared-assets/"
    },
    {
      "src": "git@github.com:crowdtap/assets.shared.git",
      "root": "shared/",
      "files": [
        "manifest.json",
        {
          "src": "css/",
          "dest": "css/shared/"
        },
        {
          "src": "images/logo.png",
          "dest": "public/images/ct-logo.png"
        }
      ]
    }
  ],
  "scripts": {
    "preinstall": "rm -rf shared/"
  }
}
```

### Host

If there is no `parachute.json` file present in the host repo, then all files will be copied into the client side at the current directory or based on the `root` option (if any). 

If you would like to have clients copy only certain files by default, you can provide a `components` option in `parachute.json`:

```javascript
{
  "components": [
    "css/mixins.less",
    {
      "src":   "assets/images/",
      "dest": "public/shared/images/"
    },
    {
      "src": "css/bootstrap.less",
      "dest": "css/boostrap/index.less"
    }
  ]
}
```

__Note:__ The client's `files` option takes precedence over the host's `components` option.

## Usage

Installing your dependencies is as simple as:

```sh
parachute install
```

To update dependencies before installing them:

```sh
parachute install --update
```

For more usage information, run `parachute -h`.

## Contributing

1. Clone the repo: `git clone https://github.com/crowdtap/parachute.git`.
2. Install dependencies: `npm install`.
3. Fire up a watch script to auto-compile source files: `npm run-script watch`.
4. Write tests under `src/test` (see: [pseudo-repositories](#pseudo-repositories)). Run them: `npm test`.
5. Write your feature(s).
6. Open a [pull request](https://help.github.com/articles/using-pull-requests)!

### Pseudo-repositories

Parachute integration tests rely on git repositories. Since we want to be able to control and track changes to local repositories, we opted for _pseudo_ repositories rather than git [submodules](http://git-scm.com/book/en/Git-Tools-Submodules) (since they only work for remote repositories).

The pseudo-repositories under `test/repos` work by tracking the `.git` directory under a folder named `git` (note the lack of a leading dot). A preinstall script does a `cp -R git .git` for each test repository, essentially converting them into real git repositories and allowing our tests to recognize them as such.

To make an update to a test repository:

1. `cd` into the directory under `test/repos`.
2. `mv git .git`
3. Make your changes and commit as you normally would.
4. `mv .git git`

## Versioning

This project follows the [Semantic Versioning](http://semver.org/spec/v2.0.0.html) system.

## License

Copyright (c) 2014 Crowdtap.

Licensed under the [MIT License](http://github.com/crowdtap/parachute/raw/master/LICENSE).
