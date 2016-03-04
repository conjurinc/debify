# 0.10.2
* Fixed publish internal Dockerfile

# 0.10.1
* Run internal containers as privileged if Docker >= 1.10.0

# 0.10.0
* Upgrading Ruby for packaging from 2.0 to 2.2.4

# 0.9.2

* Print messages to stderr instead of stdout during packaging
* Only consider tags matching v*.*.* when determining package version string

# 0.9.1

* Provide the package to purge before installing the new version

# 0.9.0

* Don't nuke the entire existing source install dir, there may be necessary files in there

# 0.8.0

* Remove the need for a 'latest' debian
* Fix bug in the error message for 'detect_version'
* Use a more reliable way to detect the current branch
* `publish` : Remove the default value of the 'component' flag
* `clean` : Don't create a container unless deletions will actually be performed

# 0.7.0

* Add `debify clean`

# 0.6.0

* `package` : Add `--dockerfile` option
* `package` : Ensure that `Gemfile.lock` is in the container
* `test` : Propagate `SSH_AUTH_SOCK` to the container
