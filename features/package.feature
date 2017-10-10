Feature: Packaging

	@announce-output
	Scenario: 'example' project can be packaged successfully
		When I run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		Then the exit status should be 0
		And the stdout should contain exactly "conjur-example_0.0.1_amd64.deb"

	@announce-output
	Scenario: 'clean' command will delete non-Git-managed files
		Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		And I successfully run `env DEBUG=true GLI_DEBUG=true debify clean -d ../../example --force`
		And I successfully run `find ../../example`
		Then the stdout from "find ../../example" should not contain "conjur-example_0.0.1_amd64.deb"

	@only @announce-output
	Scenario: 'example' project can be tested successfully
		Given I successfully run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		When I run `env DEBUG=true GLI_DEBUG=true debify test -t 4.9-stable -v 0.0.1 -d ../../example --no-pull example test.sh`
		Then the exit status should be 0
		And the stderr should contain "Test succeeded"
