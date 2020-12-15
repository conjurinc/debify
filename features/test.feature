@announce-output
Feature: Testing

  Background:
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`

  Scenario: 'example' project can be tested successfully
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify test -t 5.0-stable -v 0.0.1 -d ../../example --no-pull example test.sh`
    Then the stderr should contain "Test succeeded"

  Scenario: 'example' project can be tested when linked to another container
    Given I start a container named "other_host"
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify test -t 5.0-stable -v 0.0.1 -d ../../example --no-pull --link other_host example docker-net-test.sh`
    Then the stderr should contain "Test succeeded"

  Scenario: 'example' project can be tested on a network other than the default
    Given I start a container named "other_host" on network "test-net"
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify test -t 5.0-stable -v 0.0.1 -d ../../example --no-pull --net test-net example docker-net-test.sh`
    Then the stderr should contain "Test succeeded"

  Scenario: 'example' project can be tested on a network other than the default with a host aliased
    Given I start a container named "another_host" on network "test-net"
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify test -t 5.0-stable -v 0.0.1 -d ../../example --no-pull --link another_host:other_host --net test-net example docker-net-test.sh`
    Then the stderr should contain "Test succeeded"
