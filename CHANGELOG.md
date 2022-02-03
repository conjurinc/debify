## [3.0.0]
### Changed

- Upgrade ruby version to 3.0.
- Bump `cucumber` gem to 7.1.
- Bump `conjur-api` gem to 5.3.7.
- Bump `conjur-cli` gem to 6.2.6.
- Bump `aruba` gem to 2.0.
- Bump `jfrog-cli` to :latest.

## [2.1.1]
### Changed

- Update to use automated release process

# 2.1.0
### Changed

- Refine bundler related steps in `debify package` flow: only `package.sh` file configures
  and invokes bundler. `Dockerfile.fpm` only copies files and adjusts folder structure.
- Remove bundler 1.* support 

# 2.0.0
### Changed
- Debify now receives the flag `--output` as input to indicate the file type that it should package (e.g `rpm`). If this 
  flag is not given, the default value is `deb`.
  [conjurinc/debify#56](https://github.com/conjurinc/debify/issues/56)

# 1.12.0

### Added
- Debify now packages and publishes an RPM file, alongside a debian file.
  [conjurinc/debify#49](https://github.com/conjurinc/debify/pull/49)
- `debify package` now offers an `--additional-files` flag to provide a comma
  separated list of files to include in the FPM build that are not provided
  automatically by `git ls-files`.
  [conjurinc/debify#52](https://github.com/conjurinc/debify/pull/52)

### Fixed
- Bug causing `all` files in the git repo to be added to the debian file.
  [conjurinc/debify#50](https://github.com/conjurinc/debify/pull/50)

# 1.11.5

### Changed
* Updated FPM and Test images to use a base image with FIPS-compliant Ruby and OpenSSL.

# 1.11.4

* Updated sandbox password to match Conjur password complexity requirements.

# 1.11.3

* Reverted to `bundler` v1. `bundler` v2 was creating incompatible paths for downstream
  packages.
* Made FPM Ruby version use `ruby2.5` instead of `ruby2.6` since that is what
  our appliance image uses otherwise the gems bundled in the packages are unusable.

# 1.11.2

* Upgraded to use Ruby 2.6 and latest version of FPM
* Update Conjur Dockerfile from Ubuntu 14.04 --> 18.04 as 14.04 repos
  are now behind a [pay wall](https://ubuntu.com/blog/ubuntu-14-04-esm-support)
  Ruby is installed from `ppa:brightbox/ruby-ng` however that PPA
  [doesn't currently supply ruby2.2 for Ubuntu 18.04](https://launchpad.net/~brightbox/+archive/ubuntu/ruby-ng?field.series_filter=bionic). [The documentation](https://www.brightbox.com/docs/ruby/ubuntu/)
  suggests this combination is available, so it may be a temporary problem.
  To work around the problem, ruby is bumped from 2.2 to 2.3 as 2.3 is the oldest
  version available for Ubuntu 18.04.

# 1.11.1

* Upgrade `docker-debify` to use Ruby 2.6.

# 1.11.0

* Use a Docker env-file (docker.env, by default) to pass environment
  variables to the debify container.

* Make sure `--env` variables get passed along to the Conjur container when testing, too.

# 1.10.3

* Fix a bug causing duplicate files between normal and dev packages when a file name contained a space.

# 1.10.2

* Pin `ruby-xz` gem in fpm Dockerfile, so it works on Ruby 2.2. Upstream issue: https://github.com/jordansissel/fpm/issues/1493

# 1.10.1

* Update fpm container to use Ruby 2.4, fixes `ruby-xz` dependency

# 1.10.0

* add `--net` support to `test` and `sandbox` subcommands
* Use Docker::Container.start! to start containers, to avoid
  swallowing important errors.

# 1.9.1

* Make sure .bundle/config in the 'main' package excludes test and development groups.

# 1.9.0

* Build -dev package with development/test dependencies and use it on `debify test`.

# 1.8.2

* Install fpm dependency libffi-dev

# 1.8.1

* Make Conjur cert available in dockerized debify container
* Add a cuke for `debify publish`

# 1.8.0

* Added artifactory url option to `debify publish`, defaults to jfrog.io domain
* Added artifactory repo option to `debify publish`, defaults to 'debian-private'

# 1.7.4

* Fix publishing support in docker-debify

# 1.7.2

* Take out a `require 'pry'` that had snuck in.
* Fix `publish` subcommand, broken after factoring publish out into a separate action.

# 1.7.0

* Read artifactory credentials from the environment
  (`ARTIFACTORY_USER`, `ARTIFACTORY_PASSWORD`), only contact Conjur if
  they're not set.

# 1.6.1

* Buils a docker image to run debify, convert tests to use it, pipeline build

# 1.6.0

* When not on the master branch, `debify publish` uses the branch name as the component name, rather than always using
  `'testing'`.

# 1.5.4

* `debify publish` now checks env var `BRANCH_NAME` as well as `GIT_BRANCH`.
  Jenkins pipelines use `BRANCH_NAME`, Jenkins jobs use `GIT_BRANCH`.

# 1.5.3

* debify now uses `~/.docker/config` auth if pulling an image fails due to auth

# 1.5.2

* Use new conjurops variables in `publish` command, fall back to old conjurops

# 1.5.1

* Fix the description of the `--version` argument to indicate that the version now comes from the `VERSION` file.

# 1.5.0

* Add `detect-version` command.
* Read version from VERSION file, if it exists.

# 1.4.0

* Add `--port` sandbox option

# 1.3.1

* When testing, `docker exec` into the Conjur container to run
  `/opt/conjur/evoke/bin/wait_for_conjur`.

# 1.3.0

* Add `--volumes-from`

# 1.2.1

* Fix typo in error message

# 1.2.0

* Pin bundler to 1.11.2

# 1.1.0

* Minor workflow tweaks, and some changes to work around Docker For Mac issues

# 1.0.0

* Base image used for packaging on Ubuntu 14.04
* Install ruby2.2 and related packages

# 0.11.1

* Add `name` and `Workingdir` options to the sandbox container.

# 0.11.0

* Add `debify sandbox`.

# 0.10.2

* Fixed publish internal Dockerfile.

# 0.10.1

* Run internal containers as privileged if Docker >= 1.10.0.

# 0.10.0

* Upgrading Ruby for packaging from 2.0 to 2.2.4.

# 0.9.2

* Print messages to stderr instead of stdout during packaging.
* Only consider tags matching v*.*.* when determining package version string.

# 0.9.1

* Provide the package to purge before installing the new version.

# 0.9.0

* Don't nuke the entire existing source install dir, there may be necessary files in there.

# 0.8.0

* Remove the need for a 'latest' debian.
* Fix bug in the error message for 'detect_version'.
* Use a more reliable way to detect the current branch.
* `publish` : Remove the default value of the 'component' flag.
* `clean` : Don't create a container unless deletions will actually be performed.

# 0.7.0

* Add `debify clean`.

# 0.6.0

* `package` : Add `--dockerfile` option.
* `package` : Ensure that `Gemfile.lock` is in the container.
* `test` : Propagate `SSH_AUTH_SOCK` to the container.
