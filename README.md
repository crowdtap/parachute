# Parachute [![Build Status](https://travis-ci.org/crowdtap/parachute.png)](https://travis-ci.org/crowdtap/parachute)

A simple utility for managing shared assets across many applications.

Requires Node >=0.10 and Git >=1.8.5

## Installation

Install it globally using npm:

```bash
npm install parachute -g
```

Alternatively, add it to your project's `package.json` as a dependency:

```bash
"devDependencies": {
  "parachute": "latest"
}
```

## What is this?

Parachute is a simple utility that copies files from a host and moves them into
a local client destination. A "host" is a git repository, usually remote but a
local one works too. A "client" is where ever you're running the `parachute`
command, usually as a build step within an application.

## Manifests

A manifest file named `parachute.json` is required on the client side, and
optional on the host side. The client manifest lists which host URLs to pull
from, as well as which assets to copy and where to place them. The host may have
a manifest to indicate which files in the repo are accessible, or to bundle a
group of files under a name.

### Host configuration

You may omit the `parachute.json` manifest file on the host side. If there is no
manifest present, then all files in the host repo is accessible and the client
will pull the contents of the entire repo unless otherwise specified in its own
client manifest. Below are some host configurations and examples.

#### `only`

You can whitelist assets on the host with the `only` directive.

```
{
  "only": [
    "css/shared.css",
    { "images/*": "shared/" }
  ]
}
```

With the example above, clients by default would pull in `css/shared.css` into
their root directory, and also all of the contents (excluding directories) from
`images` into a directory called `shared`.

#### `except`

You can blacklist assets on the host with the `except` directive.

```
{
  "except": [
    "top-secret.txt",
    "src/**/*"
  ]
}
```

With the example above, clients by default would pull in all files from this
host relative to their root directory, excluding `top-secret.txt` and all files
and folders from the `src` directory.

#### `groups`

You can specify groups of files on the host as a bundle that clients can
reference in their own manifest. A kind of manifest within a manifest.

```
{
  "groups": {
    "testing": [
      "run_tests.sh",
      { "test_resources/**/*": "test/" }
    ],
    "css": [
      "bootstrap/**": "css/shared/"
    ]
  }
}
```

With the above example, clients can pick and choose which bundles they want to
pull in. A client can specify it wants the "testing" bundle, which will pull in
only `run_tests.sh` into the root directory and all files and folders from
`test_resources` into a directory called `test`.

### Client configuration

Clients must have a `parachute.json` file in their working directory from which
it runs the `parachute` command. This file lists the host dependencies, which
assets to pull in, and where to place them. This manifest file is a simple JSON
object with keys being the host git URLs or paths and the values optionally
specifying a configuration on how to pull the host's resources.

#### Default

Map hosts to a Boolean of `true` for no client configuration. If a manifest
exists on the host, it will pull in assets according to that. Otherwise, it will
pull in the entire repo contents.

```
{
  "git@github.com:crowdtap/assets.shared": true,
  "git@github.com:crowdtap/test-resources": true
}
```

#### `root`

Set a root directory to pull in all assets for a host relative to that
directory.

```
{
  "git@github.com:crowdtap/assets.shared": true,
  "git@github.com:crowdtap/test-resources": {
    "root": "test/shared/"
  }
}
```

The above example pulls in all of _assets.shared_ repo contents relative
to the current working directory. But it will pull in all of _test-resources_
repo contents and place them in a directory called `test/shared`.

#### `only`

Whitelist resources pulled from a host.

```
{
  "git@github.com:crowdtap/assets.shared": true,
  "git@github.com:crowdtap/test-resources": {
    "only": [
      "run_tests.sh",
      { "selenium/**/*": "test/shared/"
    ]
  }
}
```

The above example pulls in all of _assets.shared_ repo contents. For
_test-resources_, it pulls in `run_tests.sh` and pulls all files and directories
in `selenium` into a local directory `test/shared`.

#### `groups`

If a host manifest lists asset groups, a client can whitelist assets pulled to
any of those groups.

```
{
  "git@github.com:crowdtap/assets.shared": {
    "groups": ["bundle", "less-globals", "webdriver"]
  }
}
```

The above example will pull in the assets specified in the "bundle",
"less-globals", and "webdriver" assets groups from _assets.shared_ repo.

### Treeish

Clients can specify a treeish such as a branch or commit hash for any host to
use a version of its assets.

```
{
  "git@github.com:crowdtap/assets.shared#some-branch-name": {
    "groups": ["bundle", "less-globals", "webdriver"]
  }
}
```

## Usage

Installing your dependencies is as simple as:

```sh
parachute install
```

For more usage information, run `parachute -h`.

## Contributing

1. Clone the repo: `git clone https://github.com/crowdtap/parachute.git`.
2. Install dependencies: `npm install`.
3. Write tests under `test/`.
4. Write your feature(s).
5. Open a [pull request](https://help.github.com/articles/using-pull-requests)!

## Versioning

This project follows the [Semantic Versioning](http://semver.org/spec/v2.0.0.html) system.

## License

Copyright (c) 2015 Crowdtap.

Licensed under the [MIT License](http://github.com/crowdtap/parachute/raw/master/LICENSE).
