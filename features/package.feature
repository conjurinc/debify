@announce-output
Feature: Packaging

  Background:
    # We use version 0.0.1-suffix to verify that RPM converts dashes to underscores
    # in the version as we expect
    Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1-suffix example -- --post-install /distrib/postinstall.sh`
    And I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example --output rpm  -v 0.0.1-suffix example  -- --post-install /distrib/postinstall.sh`

  Scenario: 'example' project can be packaged successfully
    Then the output should match /conjur-example_0\.0\.1-suffix_(amd64|arm64)\.deb/
    And the output should match /conjur-example-dev_0\.0\.1-suffix_(amd64|arm64)\.deb/
    And the output should match /conjur-example-0\.0\.1_suffix-1\.(x86_64|aarch64)\.rpm/
    And the output should match /conjur-example-dev-0\.0\.1_suffix-1\.(x86_64|aarch64)\.rpm/

  Scenario: 'clean' command will delete non-Git-managed files
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify clean -d ../../example --force`
    And I cd to "../../example"
    Then a file matching %r</conjur-example_0\.0\.1-suffix_(amd64|arm64)\.deb/> should not exist
    And a file matching %r</conjur-example-0\.0\.1_suffix-1\.(x86_64|aarch64)\.rpm/> should not exist

  Scenario: 'example' project can be published
    When I successfully run `env DEBUG=true GLI_DEBUG=true debify publish -v 0.0.1-suffix -d ../../example 5.0 example`
