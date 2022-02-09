@announce-output
Feature: Automatic version string

  Scenario: 'example' project gets a default version
    When I run `env DEBUG=true GLI_DEBUG=true debify detect-version -d ../../example`
    Then the exit status should be 0
    And the output should match /\d+.\d+.\d+-\d+-.*/

  @skip
  Scenario: Test @skip tag, failed by default
    When I run `env DEBUG=true GLI_DEBUG=true debify detect-version -d ../../example`
    Then the exit status should be 1
