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
          component = cmd_options[:component] || detect_component
          package_name = "conjur-#{project_name}_#{version}_amd64.deb"

          publish_image = create_image
          DebugMixin.debug_write "Built base publish image '#{publish_image.id}'\n"

          art_url = cmd_options[:url]
          art_repo = cmd_options[:repo]

          art_user = ENV['ARTIFACTORY_USER']
          art_password = ENV['ARTIFACTORY_PASSWORD']
          unless art_user && art_password
            art_user, art_password = fetch_art_creds
          end

          options = {
            'Image' => publish_image.id,
            'Cmd' => [
              "jfrog", "rt", "upload",
              "--url", art_url,
              "--user", art_user,
              "--password", art_password,
              "--deb", "#{distribution}/#{component}/amd64",
              package_name, "#{art_repo}/"
            ],
            'Binds' => [
              [ dir, "/src" ].join(':')
            ]
          }
          options['Privileged'] = true if Docker.version['Version'] >= '1.10.0'

          publish(options)
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

        username_var = 'ci/artifactory/users/jenkins/username'
        password_var = 'ci/artifactory/users/jenkins/password'

        [conjur.variable(username_var).value, conjur.variable(password_var).value]
      end

      def publish(options)
        container = Docker::Container.create(options)
        begin
          container.tap(&:start).streaming_logs(follow: true, stdout: true, stderr: true) { |stream, chunk| puts "#{chunk}" }
          status = container.wait
          raise "Failed to publish package" unless status['StatusCode'] == 0
        ensure
          container.delete(force: true)
        end
      end

    end
  end
end
