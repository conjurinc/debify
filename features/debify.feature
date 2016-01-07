Feature: Packaging

	Scenario: 'example' project can be packaged successfully
		When I run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		Then the exit status should be 0
		And the stdout should contain exactly "conjur-example_0.0.1_amd64.deb"

	Scenario: 'example' project can be tested successfully
		Given I run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		And the exit status should be 0
		When I run `env DEBUG=true GLI_DEBUG=true debify test -d ../../example --no-pull example test.sh`
		Then the exit status should be 0
		And the stderr should contain "Test succeeded"
