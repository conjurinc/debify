Feature: Automatic version string

  @announce-output
  Scenario: 'example' project gets a default version
    When I run `env DEBUG=true GLI_DEBUG=true debify detect-version -d ../../example`
    Then the exit status should be 0
    And the output should match /\d.\d.\d-\d-.*/
