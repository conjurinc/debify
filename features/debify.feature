Feature: Packaging

	Scenario: 'example' project can be packaged successfully
		When I run `env DEBUG=true GLI_DEBUG=true debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		Then the exit status should be 0
		And the stdout should contain exactly "conjur-example_0.0.1_amd64.deb"
