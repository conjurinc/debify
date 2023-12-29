# Debify

Debify is a tool used for building and testing DAP appliance packages.
It is mainly used to package and publish debian packages that are consumed into the
appliance image in its build stage. However, it also packages and publishes an
RPM package whenever it does so for a debian.

## Installation

There are two different ways of installing debify: as a gem, or as a Docker image.

### Installing the gem
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

### Installing the Docker image
Pull the Docker image:

```sh-session
$ VERSION=3.0.0
$ docker pull registry.tld/conjurinc/debify:$VERSION
```

Images are tagged with the version specified in [VERSION](./VERSION)

Use the `config` subcommand to get a copy of the wrapper script and the secret definitions for publishing:

```sh-session
$ docker run --rm debify:$VERSION config script > docker-debify
$ chmod +x docker-debify
# Optionally, if publishing a deb
$ docker run --rm debify:$VERSION config secrets > publishing-secrets.yml
```

Running `docker-debify` will then start a container configured to run debify:

```sh-session
$ ./docker-debify help
NAME
    debify - Utility commands for building and testing Conjur appliance Debian packages

SYNOPSIS
    debify [global options] command [command options] [arguments...]

VERSION
    3.0.0


GLOBAL OPTIONS
    --env=arg           - Set an environment variable (e.g. TERM=xterm) when starting a container (may be used more than once, default:
                          none)
    --help              - Show this message
    --[no-]local-bundle - Mount local bundle to reuse gems from previous installation
    --version           - Display the program version

COMMANDS
    clean          - Clean current working directory of non-Git-managed files
    config         - Show the given configuration
    detect-version - Auto-detect and print the repository version
    help           - Shows a list of commands or help for one command
    initconfig     - Initialize the config file using current global options
    package        - Build a debian package for a project
    publish        - Publish a debian package to apt repository
    sandbox        - Setup a development sandbox for a Conjur debian package in a Conjur appliance container
    test           - Test a Conjur debian package in a Conjur appliance container
```


Note that debify itself creates images and starts containers, so it
needs access to the host's `docker.sock`. Additionally, it requires
that it be started in root directory of the project being packaged.

## Build a package

Builds a Conjur Debian package from a Ruby gem.

```
$ debify help package
NAME
    package - Build a debian package for a project

SYNOPSIS
    debify [global options] package [command options] project_name -- <fpm-arguments>
b
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
    --additional-files=arg - Specify files to add to the FPM image that are not included from the git repo (default: none)
    -d, --dir=arg          - Set the current working directory (default: none)
    --dockerfile=arg       - Specify a custom Dockerfile.fpm (default: none)
    -i, --image=arg        - Image name (default: cyberark/ubuntu-ruby-builder)
    -o, --output=arg       - Set the output file type of the fpm command (e.g rpm) (default: none)
    -t, --image-tag=arg    - Image tag, e.g. 4.5-stable, 4.6-stable (default: latest)
    -v, --version=arg      - Specify the deb version; by default, it's read from the VERSION file (default: none)
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
    debify [global options] publish [command options] distribution project-name

DESCRIPTION
    Publishes a deb created with `debify package` to our private apt repository.

    "distribution" should match the major/minor version of the Conjur appliance you want to install to.

    The package name is a required option. The package version can be specified as a CLI option, or it will be auto-detected from Git.

    --component should be 'stable' if run after package tests pass or 'testing' if the package is not yet ready for release. If you don't specify the component, it will be set to
    'testing' unless the current git branch is 'master' or 'origin/master'. The git branch is first detected from the env var GIT_BRANCH, and then by checking `git rev-parse
    --abbrev-ref HEAD` (which won't give you the answer you want when detached).

COMMAND OPTIONS
    -c, --component=arg - Maturity stage of the package, 'testing' or 'stable' (default: none)
    -d, --dir=arg       - Set the current working directory (default: none)
    -v, --version=arg   - Specify the deb package version; by default, it's computed automatically (default: none)
```

### Example usage

You will need read permission for the `ci/artifactory/users/jenkins/username` and `ci/artifactory/users/jenkins/password` variables in order to run this command from your local machine.

```sh-session
$ debify publish -c stable 0.0.1 example
[Thread 0] Uploading artifact: https://conjurinc.artifactoryonline.com/conjurinc/debian-local/conjur-example_0.1.1-c9fd618_amd64.deb;deb.distribution=0.1.1;deb.component=possum;deb.architecture=amd64
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

## Usage with docker-compose

As of v1.10.0, both the `test` and `sandbox` subcommands support the `--net` switch.
This allows you to specify a network to which the Conjur appliance container should be attached.

There are a variety of ways to make use of this feature. One possibility is creating a network
using `docker network create`, then attaching both the docker-compose services, as well, as the Conjur
appliance container created by debify, to it.

As a (somewhat contrived) example, create a new docker network:

```sh-session
$ docker network create testnet
```

Use a docker-compose file like [example/docker-compose.yml](example/docker-compose.yml)

```yaml
version: "2"
networks:
  svcnet:
    external:
      name: testnet
services:
  db:
    image: postgres
    container_name: mydb
    networks:
      - svcnet
```

Bring up the db service:

```sh-session
debify $ cd example
example $ docker-compose up -d
```

Start a sandbox, see that it can resolve the hostname `mydb`:

```sh-session

example $ debify sandbox -t 5.0-stable --net testnet
example $ docker exec -it example-sandbox /bin/bash
root@7d4217655332:/src/example# getent hosts mydb
172.19.0.2      mydb
```


## Contributing

For instructions on how to get started and
descriptions of our development workflows, please see our
[contributing guide](CONTRIBUTING.md).
