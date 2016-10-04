# Debify

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'conjur-debify'
```

And then execute:
```sh-session
$ bundle
```

Or install it yourself as a ruby gem:
```sh-session
$ gem install conjur-debify
```

## Build a package

Builds a Conjur Debian package from a Ruby gem.

```
$ debify help package
NAME
    package - Build a debian package for a project
    
SYNOPSIS
    debify [global options] package [command options] project_name -- <fpm-arguments>

DESCRIPTION
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
    -v, --version=arg - Specify the deb version; by default, it's read from the VERSION file (default: none)
```

### Example usage

```sh-session
$ package_name=$(debify package -d example -v 0.0.1 example -- --post-install /distrib/postinstall.sh)
$ echo $package_name
conjur-example_0.0.1_amd64.deb
```

## Test a package

```
$ debify help test
NAME
    test - Test a Conjur debian package in a Conjur appliance container

SYNOPSIS
    debify [global options] test [command options] project-name test-script

DESCRIPTION
    First, a Conjur appliance container is created and started. By default, the container image is registry.tld/conjur-appliance-cuke-master. An image tag
    MUST be supplied. This image is configured with all the CONJUR_ environment variables setup for the local environment (appliance URL, cert path, admin
    username and password, etc). The project source tree is also mounted into the container, at /src/<project-name>.

    This command then waits for Conjur to initialize and be healthy. It proceeds by installing the conjur-<project-name>_latest_amd64.deb from the project
    working directory.

    Then the evoke "test-install" command is used to install the test code in the /src/<project-name>. Basically, the development bundle is installed and
    the database configuration (if any) is setup.

    Next, an optional "configure-script" from the project source tree is run, with the container id as the program argument. This command waits for Conjur
    to be healthy again.

    Finally, a test script from the project source tree is run, again with the container id as the program argument.

    Then the Conjur container is deleted (use --keep to leave it running). 

COMMAND OPTIONS
    -c, --configure-script=arg - Shell script to configure the appliance before testing (default: none)
    -d, --dir=arg              - Set the current working directory (default: none)
    -i, --image=arg            - Image name (default: registry.tld/conjur-appliance-cuke-master)
    -k, --[no-]keep            - Keep the Conjur appliance container after the command finishes
    --[no-]pull                - Pull the image, even if it's in the Docker engine already (default: enabled)
    -t, --image-tag=arg        - Image tag, e.g. 4.5-stable, 4.6-stable (default: none)
```

### Example usage

```sh-session
$ debify test -i conjur-appliance-cuke-master --image-tag 4.6-dev --no-pull -d example example test.sh
```

## Publish a package

```
$ debify help publish
NAME
    publish - Publish a debian package to apt repository

SYNOPSIS
    debify [global options] publish [command options] package

DESCRIPTION
    Publishes a deb created with `debify package` to our private apt
    repository.

    You can use wildcards to select packages to publish, e.g., debify
    publish *.deb.

    --distribution should match the major/minor version of the Conjur
    appliance you want to install to.

    --component should be 'stable' if run after package tests pass or
    'testing' if the package is not yet ready for release.

    ARTIFACTORY_USERNAME and ARTIFACTORY_PASSWORD must be available
    in the environment for upload to succeed.

COMMAND OPTIONS
    -c, --component=arg    - Maturity stage of the package, 'testing'
                             or 'stable' (default: testing)
    -d, --distribution=arg - Lock packages to a Conjur appliance
                             version (default: 4.6)
```

### Example usage

Assuming a `secrets.yml` like this exists in the source directory and that you have `summon` with the Conjur provider installed on the machine:

```yaml
ARTIFACTORY_USERNAME: !var artifactory/users/jenkins/username
ARTIFACTORY_PASSWORD: !var artifactory/users/jenkins/password
```

```sh-session
$ summon debify publish -c stable conjur-example_0.0.1_amd64.deb
[Thread 0] Uploading artifact: https://conjurinc.artifactoryonline.com/conjurinc/debian-local/test.deb;deb.distribution=4.6;deb.component=stable;deb.architecture=amd64
[Thread 0] Artifactory response: 201 Created
Uploaded 1 artifacts to Artifactory.
```

## Create a development session in a Conjur appliance container


```
$ debify help sandbox
NAME
    sandbox - Setup a development sandbox for a Conjur debian package in a Conjur appliance container

SYNOPSIS
    debify [global options] sandbox [command options] 

DESCRIPTION
    First, a Conjur appliance container is created and started. By default, the container image is 
    registry.tld/conjur-appliance-cuke-master. An image tag MUST be supplied. This image
    is configured with all the CONJUR_ environment variables setup for the local environment (appliance URL, 
    cert path, admin username and password, etc). The project source tree is
    also mounted into the container, at /src/<project-name>, where <project-name> is taken from the name of the 
    current working directory.

    Once in the container, use "/opt/conjur/evoke/bin/dev-install" to install the development bundle of your project. 

COMMAND OPTIONS
    --bind=arg          - Bind another source directory into the container. Use <src>:<dest>, where both are full paths. (default: none)
    -d, --dir=arg       - Set the current working directory (default: none)
    -i, --image=arg     - Image name (default: registry.tld/conjur-appliance-cuke-master)
    --[no-]pull         - 'docker pull' the Conjur container image
    -t, --image-tag=arg - Image tag, e.g. 4.5-stable, 4.6-stable (default: none)
```

### Example usage

```sh-session
authz $ debify sandbox -t $(cat VERSION_APPLIANCE)-stable
... much logging
authz $ docker exec -it authz-sandbox bash
root@7d4217655332:/src/authz# /opt/conjur/evoke/bin/dev-install authz
...
root@7d4217655332:/src/authz# export RAILS_ENV=test
root@7d4217655332:/src/authz# bundle exec rake db:migrate
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/debify/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
