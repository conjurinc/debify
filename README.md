# Debify

Builds a Conjur Debian package from a Ruby gem.

```
$ debify help package
NAME
    package - 

SYNOPSIS
    debify [global options] package [command options] project_name -- <fpm-arguments>

DESCRIPTION
    Build a debian package for a project.

    The package is built using fpm (https://github.com/jordansissel/fpm).

    The project directory is required to contain:

    * A Gemfile and Gemfile.lock * A shell script called debify.sh

    debify.sh is invoked by the package build process to create any custom files, other than the project source tree. For example, config files can be
    created in /opt/conjur/etc.

    The distrib folder in the project source tree is intended to create scripts for package pre-install, post-install etc. The distrib folder is not
    included in the deb package, so its contents should be copied to the file system or packaged using fpm arguments.

    All arguments to this command which follow the double-dash are propagated to the fpm command. 

COMMAND OPTIONS
    -d, --dir=arg     - Set the current working directory (default: none)
    -v, --version=arg - Specify the deb version; by default, it's computed from the Git tag (default: none)
```

## Example usage

```sh-session
$ package_name=$(debify package -d example -v 0.0.1 example -- --post-install /distrib/postinstall.sh)
$ echo $package_name
conjur-example_0.0.1_amd64.deb
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'debify'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install debify

## Contributing

1. Fork it ( https://github.com/[my-github-username]/debify/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
