@announce-output
Feature: Running a sandbox
  Background:
    Given I successfully run `docker pull registry.tld/conjur-appliance-cuke-master:5.0-stable`
    # The extra containers will use the `alpine` image, so we need to pull it first on the
    # host to use the authenticated DockerHub connection. This avoids hitting DockerHub
    # rate limits.
    And I successfully run `docker pull nginx`

  Scenario: sandbox for 'example' project be started
    Given I successfully start a sandbox for "example" with arguments "-t 5.0-stable --no-pull"

  Scenario: sandbox for 'example' project be started linked to another container
    Given I start a container named "other_host"
    Then I successfully start a sandbox for "example" with arguments "-t 5.0-stable --no-pull --link other_host -c 'curl -s http://other_host > /dev/null'"

  Scenario: sandbox for 'example' project be started on a network other than the default
    Given I start a container named "other_host" on network "test-net"
    Then I successfully start a sandbox for "example" with arguments "-t 5.0-stable --no-pull --net test-net -c 'curl -s http://other_host > /dev/null'"

  Scenario: sandbox for 'example' project be started on a network other than the default with a host aliased
    Given I start a container named "another_host" on network "test-net"
    Then I successfully start a sandbox for "example" with arguments "-t 5.0-stable --no-pull --net test-net --link another_host:other_host -c 'curl -s http://other_host > /dev/null'"
