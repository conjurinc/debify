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
