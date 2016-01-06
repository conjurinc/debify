Feature: Packaging

	Scenario: 'example' project can be packaged successfully
		When I run `debify package -d ../../example -v 0.0.1 example -- --post-install /distrib/postinstall.sh`
		Then the exit status should be 0
