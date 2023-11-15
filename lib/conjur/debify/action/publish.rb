module Conjur::Debify
  module Action
    class Publish

      def detect_component
        branch = ENV['GIT_BRANCH'] || ENV['BRANCH_NAME'] || `git rev-parse --abbrev-ref HEAD`.strip
        if %w(master origin/master).include?(branch)
          'stable'
        else
          branch.gsub('/', '.')
        end
      end

      attr_reader :distribution, :project_name, :cmd_options
      def initialize(distribution, project_name, cmd_options)
        @distribution = distribution
        @project_name = project_name
        @cmd_options = cmd_options
      end

      def run
        dir = cmd_options[:dir] || '.'
        dir = File.expand_path(dir)
        raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)

        Dir.chdir dir do
          version = cmd_options[:version] || detect_version

          publish_image = create_image
          DebugMixin.debug_write "Built base publish image '#{publish_image.id}'\n"

          art_url = cmd_options[:url]
          deb_art_repo = cmd_options[:repo]

          art_user = ENV['ARTIFACTORY_USER']
          art_password = ENV['ARTIFACTORY_PASSWORD']
          unless art_user && art_password
            art_user, art_password = fetch_art_creds
          end

          # Publish AMD64 deb package
          component = cmd_options[:component] || detect_component
          deb_info = "#{distribution}/#{component}/amd64"
          package_name = "conjur-#{project_name}_#{version}_amd64.deb"
          publish_package(
            publish_image: publish_image,
            art_url: art_url,
            art_user: art_user,
            art_password: art_password,
            art_repo: deb_art_repo,
            package_name: package_name,
            dir: dir,
            deb_info: deb_info
          )

          # (Optional) Publish ARM64 deb package
          unless Dir.glob('*_arm64.deb').empty?
            deb_info = "#{distribution}/#{component}/arm64"
            package_name = "conjur-#{project_name}_#{version}_arm64.deb"
            publish_package(
              publish_image: publish_image,
              art_url: art_url,
              art_user: art_user,
              art_password: art_password,
              art_repo: deb_art_repo,
              package_name: package_name,
              dir: dir,
              deb_info: deb_info
            )
          end

          # Publish RPM package
          # The rpm builder replaces dashes with underscores in the version
          rpm_version = version.tr('-', '_')
          package_name = "conjur-#{project_name}-#{rpm_version}-1.*.rpm"
          rpm_art_repo = cmd_options['rpm-repo']
          publish_package(
            publish_image: publish_image,
            art_url: art_url,
            art_user: art_user,
            art_password: art_password,
            art_repo: rpm_art_repo,
            package_name: package_name,
            dir: dir
          )
        end
      end

      def create_image
        Docker::Image.build_from_dir File.expand_path('../../publish', File.dirname(__FILE__)), tag: "debify-publish", &DebugMixin::DOCKER
      end

      def fetch_art_creds
        require 'conjur/cli'
        require 'conjur/authn'
        Conjur::Config.load
        Conjur::Config.apply
        conjur = Conjur::Authn.connect nil, noask: true

        account = Conjur.configuration.account
        username_var = [account, "variable", "ci/artifactory/users/jenkins/username"].join(':')
        password_var = [account, "variable", 'ci/artifactory/users/jenkins/password'].join(':')
        [conjur.resource(username_var).value, conjur.resource(password_var).value]
      end

      def publish_package(
        publish_image:,
        art_url:,
        art_user:,
        art_password:,
        art_repo:,
        package_name:,
        dir:,
        deb_info: nil
      )

        cmd_args = [
          "jfrog", "rt", "upload",
          "--url", art_url,
          "--user", art_user,
          "--password", art_password,
        ]

        cmd_args += ["--deb", deb_info] if deb_info
        cmd_args += [package_name, "#{art_repo}/"]

        options = {
          'Image' => publish_image.id,
          'Cmd' => cmd_args,
          'Binds' => [
            [ dir, "/src" ].join(':')
          ]
        }
        options['Privileged'] = true if Docker.version['Version'] >= '1.10.0'

        publish(options)
      end

      def publish(options)
        container = Docker::Container.create(options)
        begin
          container.tap(&:start!).streaming_logs(follow: true, stdout: true, stderr: true) { |stream, chunk| puts "#{chunk}" }
          status = container.wait
          raise "Failed to publish package" unless status['StatusCode'] == 0
        ensure
          container.delete(force: true)
        end
      end

    end
  end
end
