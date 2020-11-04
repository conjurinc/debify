@announce-output
Feature: Packaging

  Background:
    # We use version 0.0.1-suffix to verify that RPM converts dashes to underscores
    # in the version as we expect
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix example -- --post-install /distrib/postinstall.sh`

  Scenario: 'example' project can be packaged successfully
    Then the stdout should contain "conjur-example_0.0.1-suffix_amd64.deb"
    And the stdout should contain "conjur-example-dev_0.0.1-suffix_amd64.deb"
    And the stdout should contain "conjur-example-0.0.1_suffix-1.x86_64.rpm"
    And the stdout should contain "conjur-example-dev-0.0.1_suffix-1.x86_64.rpm"

  Scenario: 'clean' command will delete non-Git-managed files
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify clean -d ../../example --force`
    And I successfully run `find ../../example`
    Then the stdout from "find ../../example" should not contain "conjur-example_0.0.1-suffix_amd64.deb"
    And the stdout from "find ../../example" should not contain "conjur-example-0.0.1_suffix-1.x86_64.rpm"

  Scenario: 'example' project can be published
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify publish -v 0.0.1-suffix -d ../../example 4.9 example`
