@announce-output
Feature: Packaging

  Background:
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`

  Scenario: 'example' project can be packaged successfully
    Then the stdout should contain "conjur-example_0.0.1_amd64.deb"
    And the stdout should contain "conjur-example-dev_0.0.1_amd64.deb"

  Scenario: 'clean' command will delete non-Git-managed files
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify clean -d ../../example --force`
    And I successfully run `find ../../example`
    Then the stdout from "find ../../example" should not contain "conjur-example_0.0.1_amd64.deb"
    
  Scenario: 'example' project can be published
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify publish -v 0.0.1 -d ../../example 4.9 example`
