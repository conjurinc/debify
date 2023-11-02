@announce-output
Feature: Packaging

  Background:
    # We use version 0.0.1-suffix to verify that RPM converts dashes to underscores
    # in the version as we expect


  Scenario: 'example' project can be packaged successfully for amd64
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix --architecture=amd64 example -- --post-install /distrib/postinstall.sh`
    And I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example --output rpm  -v 0.0.1-suffix --architecture=amd64 example  -- --post-install /distrib/postinstall.sh`
    Then the stdout should contain "conjur-example_0.0.1-suffix_amd64.deb"
    And the stdout should contain "conjur-example-dev_0.0.1-suffix_amd64.deb"
    And the stdout should contain "conjur-example-0.0.1_suffix-1.x86_64.rpm"
    And the stdout should contain "conjur-example-dev-0.0.1_suffix-1.x86_64.rpm"

  Scenario: 'clean' command will delete non-Git-managed files for amd64
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix --architecture=amd64 example -- --post-install /distrib/postinstall.sh`
    And I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example --output rpm  -v 0.0.1-suffix --architecture=amd64 example  -- --post-install /distrib/postinstall.sh`
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify clean -d ../../example --force`
    And I successfully run `find ../../example`
    Then the stdout from "find ../../example" should not contain "conjur-example_0.0.1-suffix_amd64.deb"
    And the stdout from "find ../../example" should not contain "conjur-example-0.0.1_suffix-1.x86_64.rpm"

  Scenario: 'example' project can be packaged successfully for arm64
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix --architecture=aarch64 example -- --post-install /distrib/postinstall.sh`
    And I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example --output rpm  -v 0.0.1-suffix --architecture=aarch64 example  -- --post-install /distrib/postinstall.sh`
    Then the stdout should contain "conjur-example_0.0.1-suffix_arm64.deb"
    And the stdout should contain "conjur-example-dev_0.0.1-suffix_arm64.deb"
    And the stdout should contain "conjur-example-0.0.1_suffix-1.aarch64.rpm"
    And the stdout should contain "conjur-example-dev-0.0.1_suffix-1.aarch64.rpm"

  Scenario: 'clean' command will delete non-Git-managed files for arm64
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix --architecture=aarch64 example -- --post-install /distrib/postinstall.sh`
    And I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example --output rpm  -v 0.0.1-suffix --architecture=aarch64 example  -- --post-install /distrib/postinstall.sh`
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify clean -d ../../example --force`
    And I successfully run `find ../../example`
    Then the stdout from "find ../../example" should not contain "conjur-example_0.0.1-suffix_arm64.deb"
    And the stdout from "find ../../example" should not contain "conjur-example-0.0.1_suffix-1.aarch64.rpm"

  Scenario: 'example' project can be published
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix example -- --post-install /distrib/postinstall.sh`
    And I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example --output rpm  -v 0.0.1-suffix example  -- --post-install /distrib/postinstall.sh`
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify publish -v 0.0.1-suffix -d ../../example 5.0 example`
