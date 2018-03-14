@announce-output
Feature: Running a sandbox
  Background:
    Given I successfully run `docker pull registry.tld/conjur-appliance-cuke-master:4.9-stable`

  Scenario: sandbox for 'example' project be started
    Given I successfully start a sandbox for "example" with arguments "-t 4.9-stable --no-pull"

  Scenario: sandbox for 'example' project be started linked to another container
    Given I start a container named "other_host"
    Then I successfully start a sandbox for "example" with arguments "-t 4.9-stable --no-pull --link other_host -c 'ping -c1 other_host'"

  Scenario: sandbox for 'example' project be started on a network other than the default
    Given I start a container named "other_host" on network "test-net"
    Then I successfully start a sandbox for "example" with arguments "-t 4.9-stable --no-pull --net test-net -c 'ping -c1 other_host'"
