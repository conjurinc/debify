# 0.8.0

* Remove the need for a 'latest' debian
* Fix bug in the error message for 'detect_version'
* Use a more reliable way to detect the current branch
* Remove the default value of the 'component' flag

# 0.7.0

* Add `debify clean`

# 0.6.0

* `package` : Add `--dockerfile` option
* `package` : Ensure that `Gemfile.lock` is in the container
* `test` : Propagate `SSH_AUTH_SOCK` to the container
