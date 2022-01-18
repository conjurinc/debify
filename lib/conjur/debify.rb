require "conjur/debify/version"
require 'docker'
require 'fileutils'
require 'gli'
require 'json'
require 'base64'
require 'tmpdir'

require 'conjur/debify/utils'

require 'active_support'
require 'active_support/core_ext'

include GLI::App

DEFAULT_FILE_TYPE = "deb"

config_file '.debifyrc'

desc 'Set an environment variable (e.g. TERM=xterm) when starting a container'
flag [:env], :multiple => true

desc 'Mount local bundle to reuse gems from previous installation'
default_value true
switch [:'local-bundle']


Docker.options[:read_timeout] = 300

# This is used to turn on DEBUG notices.
module DebugMixin
  DEBUG = ENV['DEBUG'].nil? ? true : ENV['DEBUG'].downcase == 'true'

  def debug *a
    DebugMixin.debug *a
  end

  def self.debug *a
    $stderr.puts *a if DEBUG
  end

  def debug_write *a
    DebugMixin.debug_write *a
  end

  def self.debug_write *a
    $stderr.write *a if DEBUG
  end

  # you can give this to various docker methods to print output if debug is on
  def self.docker_debug *a
    if a.length == 2 && a[0].is_a?(Symbol)
      debug a.last
    else
      a.each do |line|
        begin
          line = JSON.parse(line)
          line.keys.each do |k|
            debug line[k]
          end
        rescue JSON::ParserError
          # Docker For Mac is spitting out invalid JSON, so just print
          # out the line if parsing fails.
          debug line
        end
      end
    end
  end

  DOCKER = method :docker_debug
end

program_desc 'Utility commands for building and testing Conjur appliance Debian packages'

version Conjur::Debify::VERSION

subcommand_option_handling :normal
arguments :strict

def detect_version
  if File.exists?("VERSION") && !(base_commit = `git log --pretty='%h' VERSION | head -n 1`.strip).empty?
    base_version = File.read("VERSION").strip
    commits_since = `git log #{base_commit}..HEAD --pretty='%h'`.split("\n").size
    hash = `git rev-parse --short HEAD`.strip
    [[base_version, commits_since].join('.'), hash].join("-")
  else
    `git describe --long --tags --abbrev=7 --match 'v*.*.*' | sed -e 's/^v//'`.strip.tap do |version|
      raise "No Git version (tag) for project" if version.empty?
    end
  end
end

def git_files
  files = (`git ls-files -z`.split("\x0") + ['Gemfile.lock', 'VERSION']).uniq
  # Since submodule directories are listed, but are not files, we remove them.
  # Currently, `conjur-project-config` is the only submodule in Conjur, and it
  # can safely be removed because it's a developer-only tool.  If we add another
  # submodule in the future needed for production, we'll need to update this
  # code.  But YAGNI for now.
  files.select { |f| File.file?(f) }
end

def login_to_registry(appliance_image_id)
  config_file = File.expand_path('~/.docker/config.json')
  if File.exist? config_file
    json_config = JSON.parse(File.read(config_file))
    registry = appliance_image_id.split('/')[0]

    json_auth = json_config['auths'][registry]['auth']
    if json_auth
      username, password = Base64.decode64(json_auth).split(':')
      Docker.authenticate! username: username, password: password, serveraddress: registry
    end
  end
end

desc "Clean current working directory of non-Git-managed files"
long_desc <<DESC
Reliable builds depend on having a clean working directory.

Because debify runs some commands in volume-mounted Docker containers,
it is capable of creating root-owned files.

This command will delete all files in the working directory that are not
git-managed. The command is designed to run in Jenkins. Therefore, it will
only perform file deletion if:

* The current user, as provided by Etc.getlogin, is 'jenkins'
* The BUILD_NUMBER environment variable is set

File deletion can be compelled using the "force" option.
DESC
arg_name "project-name -- <fpm-arguments>"
command "clean" do |c|
  c.desc "Set the current working directory"
  c.flag [:d, "dir"]

  c.desc "Ignore (don't delete) a file or directory"
  c.flag [:i, :ignore]

  c.desc "Force file deletion even if if this doesn't look like a Jenkins environment"
  c.switch [:force]

  c.action do |global_options, cmd_options, args|
    def looks_like_jenkins?
      require 'etc'
      Etc.getlogin == 'jenkins' && ENV['BUILD_NUMBER']
    end

    require 'set'
    perform_deletion = cmd_options[:force] || looks_like_jenkins?
    if !perform_deletion
      $stderr.puts "No --force, and this doesn't look like Jenkins. I won't actually delete anything"
    end
    @ignore_list = Array(cmd_options[:ignore]) + ['.', '..', '.git']

    def ignore_file? f
      @ignore_list.find { |ignore| f.index(ignore) == 0 }
    end

    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)
    Dir.chdir dir do
      require 'find'
      find_files = []
      Find.find('.').each do |p|
        find_files.push p[2..-1]
      end
      find_files.compact!
      delete_files = (find_files - git_files)
      delete_files.delete_if { |file|
        File.directory?(file) || ignore_file?(file)
      }
      if perform_deletion
        image = Docker::Image.create 'fromImage' => "alpine:3.3"
        options = {
          'Cmd' => ["sh", "-c", "while true; do sleep 1; done"],
          'Image' => image.id,
          'Binds' => [
            [dir, "/src"].join(':'),
          ]
        }
        options['Privileged'] = true if Docker.version['Version'] >= '1.10.0'
        container = Docker::Container.create options
        begin
          container.start!
          delete_files.each do |file|
            puts file

            file = "/src/#{file}"
            cmd = ["rm", "-f", file]

            stdout, stderr, status = container.exec cmd, &DebugMixin::DOCKER
            $stderr.puts "Failed to delete #{file}" unless status == 0
          end
        ensure
          container.delete force: true
        end
      else
        delete_files.each do |file|
          puts file
        end
      end
    end
  end
end

def copy_packages_from_container(container, package_name, dev_package_name)
  Conjur::Debify::Utils.copy_from_container container, "/src/#{package_name}"
  puts "#{package_name}"
  begin
    Conjur::Debify::Utils.copy_from_container container, "/dev-pkg/#{dev_package_name}"
    puts "#{dev_package_name}"
  rescue Docker::Error::NotFoundError
    warn "#{dev_package_name} not found. The package might not have any development dependencies."
  end
end

desc "Build a debian package for a project"
long_desc <<DESC
The package is built using fpm (https://github.com/jordansissel/fpm).

The project directory is required to contain:

* A Gemfile and Gemfile.lock
* A shell script called debify.sh

debify.sh is invoked by the package build process to create any custom
files, other than the project source tree. For example, config files can be
created in /opt/conjur/etc.

The distrib folder in the project source tree is intended to create scripts
for package pre-install, post-install etc. The distrib folder is not included
in the deb package, so its contents should be copied to the file system or
packaged using fpm arguments.

All arguments to this command which follow the double-dash are propagated to
the fpm command.
DESC
arg_name "project-name -- <fpm-arguments>"
command "package" do |c|
  c.desc "Set the current working directory"
  c.flag [:d, "dir"]

  c.desc "Set the output file type of the fpm command (e.g rpm)"
  c.flag [:o, :output]

  c.desc "Specify the deb version; by default, it's read from the VERSION file"
  c.flag [:v, :version]

  c.desc "Specify a custom Dockerfile.fpm"
  c.flag [:dockerfile]

  c.desc "Specify files to add to the FPM image that are not included from the git repo"
  c.flag [:'additional-files']

  c.action do |global_options, cmd_options, args|
    raise "project-name is required" unless project_name = args.shift

    fpm_args = []
    if (delimeter = args.shift) == '--'
      fpm_args = args.dup
    else
      raise "Unexpected argument '#{delimeter}'"
    end

    dir = cmd_options[:dir] || '.'
    pwd = File.dirname(__FILE__)

    additional_files = []
    if cmd_options[:'additional-files']
      additional_files = cmd_options[:'additional-files'].split(',').map(&:strip)
    end

    begin
      tries ||= 2
      fpm_image = Docker::Image.build_from_dir File.expand_path('fpm', File.dirname(__FILE__)), tag: "debify-fpm", &DebugMixin::DOCKER
    rescue
      image_id = File.readlines(File.expand_path('fpm/Dockerfile', File.dirname(__FILE__)))
                     .find { | line | line =~ /^FROM/ }
                     .split(' ')
                     .last
      login_to_registry image_id
      retry unless (tries -= 1).zero?
    end
    DebugMixin.debug_write "Built base fpm image '#{fpm_image.id}'\n"
    dir = File.expand_path(dir)

    Dir.chdir dir do
      version = cmd_options[:version] || detect_version

      # move git files and Dockerfile to temp dir to make deb from
      # we do this to avoid adding "non-git" files
      # that aren't mentioned in the dockerignore to the deb
      temp_dir = Dir.mktmpdir
      DebugMixin.debug_write "Copying git files to tmp dir '#{temp_dir}'\n"
      (git_files + additional_files).each do |fname|
        original_file = File.join(dir, fname)
        destination_path = File.join(temp_dir, fname)
        FileUtils.mkdir_p(File.dirname(destination_path))
        FileUtils.cp(original_file, destination_path)
      end

      # rename specified dockerfile to 'Dockerfile' during copy, incase name is different
      dockerfile_path = cmd_options[:dockerfile] || File.expand_path("debify/Dockerfile.fpm", pwd)
      temp_dockerfile = File.join(temp_dir, "Dockerfile")

      # change image variable in specified Dockerfile
      dockerfile = File.read(dockerfile_path)
      replace_image = dockerfile.gsub("@@image@@", fpm_image.id)
      File.open(temp_dockerfile, "w") { |file| file.puts replace_image }

      # build image from project being debified dir
      image = Docker::Image.build_from_dir temp_dir, &DebugMixin::DOCKER

      DebugMixin.debug_write "Built fpm image '#{image.id}' for project #{project_name}\n"

      container_cmd_options = [project_name, version]

      # Set the output file type if present
      file_type = cmd_options[:output] || DEFAULT_FILE_TYPE
      container_cmd_options << "--file-type=#{file_type}"

      options = {
        'Cmd' => container_cmd_options + fpm_args,
        'Image' => image.id
      }
      options['Privileged'] = true if Docker.version['Version'] >= '1.10.0'

      container = Docker::Container.create options
      begin
        DebugMixin.debug_write "Packaging #{project_name} in container #{container.id}\n"
        container.tap(&:start!).streaming_logs(follow: true, stdout: true, stderr: true) { |stream, chunk| $stderr.puts "#{chunk}" }
        status = container.wait
        raise "Failed to package #{project_name}" unless status['StatusCode'] == 0

        if file_type == "deb"
          # Copy deb packages
          copy_packages_from_container(
            container,
            "conjur-#{project_name}_#{version}_amd64.deb",
            "conjur-#{project_name}-dev_#{version}_amd64.deb"
          )
        elsif file_type == "rpm"
          # Copy rpm packages
          # The rpm builder replaces dashes with underscores in the version
          rpm_version = version.tr('-', '_')
          copy_packages_from_container(
            container,
            "conjur-#{project_name}-#{rpm_version}-1.x86_64.rpm",
            "conjur-#{project_name}-dev-#{rpm_version}-1.x86_64.rpm"
          )
        end
      ensure
        container.delete(force: true)
      end
    end
  end
end

def container_command container, *args
  stdout, stderr, exitcode = container.exec args, &DebugMixin::DOCKER
  exit_now! "Command failed : #{args.join(' ')}", exitcode unless exitcode == 0
  stdout
end

def wait_for_conjur appliance_image, container
  container_command container, '/opt/conjur/evoke/bin/wait_for_conjur'
rescue
  $stderr.puts container.logs
  raise
end

def network_options(cmd)
  cmd.desc "Specify link for test container"
  cmd.flag [:l, :link], :multiple => true

  cmd.desc 'Attach to the specified network'
  cmd.flag [:n, :net]
end

def short_id(id)
  if id =~ /\A[0-9a-f]{64}\z/ # 64 hex digits, docker only allows lower case letters in ids
    $stderr.puts "Warning: found full container id, using short id instead (#{id[0..11]} for #{id})"
    id[0..11]
  else
    id
  end
end

# If the source of the link is a full container id, use the short id
# instead. (Docker doesn't add full container ids as network aliases,
# only short ids).
def shorten_source_id(link)
  src, dest = link.split(':')
  src && dest ? "#{short_id(src)}:#{dest}" : link
end

def add_network_config(container_config, cmd_options)
  host_config = container_config['HostConfig']
  has_links = cmd_options[:link] && !cmd_options[:link].empty?
  net_name = cmd_options[:net]
  if net_name
    host_config['NetworkMode'] = net_name
    if has_links
      container_config['NetworkingConfig'] ||= {}
      container_config['NetworkingConfig'].deep_merge!(
        'EndpointsConfig' => {
          net_name => {
            'Links' => cmd_options[:link].collect(&method(:shorten_source_id))
          }
        }
      )
    end
  elsif has_links
    # Don't shorten source ids here
    host_config['Links'] = cmd_options[:link]
  end
end

desc "Test a Conjur debian package in a Conjur appliance container"
long_desc <<DESC
First, a Conjur appliance container is created and started. By default, the
container image is registry.tld/conjur-appliance-cuke-master. An image tag
MUST be supplied. This image is configured with all the CONJUR_ environment
variables setup for the local environment (appliance URL, cert path, admin username and
password, etc). The project source tree is also mounted into the container, at
/src/<project-name>.

This command then waits for Conjur to initialize and be healthy. It proceeds by
installing the conjur-<project-name>_<version>_amd64.deb from the project working directory.

Then the evoke "test-install" command is used to install the test code in the
/src/<project-name>. Basically, the development bundle is installed and the database
configuration (if any) is setup.

Finally, a test script from the project source tree is run, again with the container
id as the program argument.

Then the Conjur container is deleted (use --keep to leave it running).
DESC
arg_name "project-name test-script"
command "test" do |c|
  c.desc "Set the current working directory"
  c.flag [:d, :dir]

  c.desc "Keep the Conjur appliance container after the command finishes"
  c.default_value false
  c.switch [:k, :keep]

  c.desc "Image name"
  c.default_value "registry.tld/conjur-appliance-cuke-master"
  c.flag [:i, :image]

  c.desc "Image tag, e.g. 4.5-stable, 4.6-stable"
  c.flag [:t, "image-tag"]

  c.desc "'docker pull' the Conjur container image"
  c.default_value true
  c.switch [:pull]

  c.desc "Specify the deb version; by default, it's read from the VERSION file"
  c.flag [:v, :version]

  c.desc "Specify volume for test container"
  c.flag [:'volumes-from'], :multiple => true

  network_options(c)

  c.action do |global_options, cmd_options, args|
    raise "project-name is required" unless project_name = args.shift
    raise "test-script is required" unless test_script = args.shift
    raise "Received extra command-line arguments" if args.shift

    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)

    raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)
    raise "Directory #{dir} does not contain a .deb file" unless Dir["#{dir}/*.deb"].length >= 1

    Dir.chdir dir do
      image_tag = cmd_options["image-tag"] or raise "image-tag is required"
      appliance_image_id = [cmd_options[:image], image_tag].join(":")
      version = cmd_options[:version] || detect_version
      package_name = "conjur-#{project_name}_#{version}_amd64.deb"
      dev_package_name = "conjur-#{project_name}-dev_#{version}_amd64.deb"

      raise "#{test_script} does not exist or is not a file" unless File.file?(test_script)

      begin
        tries ||= 2
        Docker::Image.create 'fromImage' => appliance_image_id, &DebugMixin::DOCKER if cmd_options[:pull]
      rescue
        login_to_registry appliance_image_id
        retry unless (tries -= 1).zero?
      end


      def build_test_image(appliance_image_id, project_name, packages)
        packages = packages.join " "
        dockerfile = <<-DOCKERFILE
FROM #{appliance_image_id}

COPY #{packages} /tmp/

RUN if dpkg --list | grep conjur-#{project_name}; then dpkg --force all --purge conjur-#{project_name}; fi
RUN if [ -f /opt/conjur/etc/#{project_name}.conf ]; then rm /opt/conjur/etc/#{project_name}.conf; fi
RUN cd /tmp; dpkg --install #{packages}

RUN touch /etc/service/conjur/down
        DOCKERFILE
        Dir.mktmpdir do |tmpdir|
          tmpfile = Tempfile.new('Dockerfile', tmpdir)
          File.write(tmpfile, dockerfile)
          dockerfile_name = File.basename(tmpfile.path)
          tar_cmd = "tar -cvzh -C #{tmpdir} #{dockerfile_name} -C #{Dir.pwd} #{packages}"
          tar = open("| #{tar_cmd}")
          begin
            Docker::Image.build_from_tar(tar, :dockerfile => dockerfile_name, &DebugMixin::DOCKER)
          ensure
            tar.close
          end
        end
      end

      packages = [package_name]
      packages << dev_package_name if File.exist? dev_package_name

      begin
        tries ||= 2
        appliance_image = build_test_image(appliance_image_id, project_name, packages)
      rescue
        login_to_registry appliance_image_id
        retry unless (tries -= 1).zero?
      end

      vendor_dir = File.expand_path("tmp/debify/#{project_name}/vendor", ENV['HOME'])
      dot_bundle_dir = File.expand_path("tmp/debify/#{project_name}/.bundle", ENV['HOME'])
      FileUtils.mkdir_p vendor_dir
      FileUtils.mkdir_p dot_bundle_dir
      options = {
        'Image' => appliance_image.id,
        'Env' => [
          "CONJUR_AUTHN_LOGIN=admin",
          "CONJUR_ENV=appliance",
          "CONJUR_AUTHN_API_KEY=SEcret12!!!!",
          "CONJUR_ADMIN_PASSWORD=SEcret12!!!!",
        ] + global_options[:env],
        'HostConfig' => {
          'Binds' => [
            [dir, "/src/#{project_name}"].join(':')
          ]
        }
      }
      host_config = options['HostConfig']

      host_config['Privileged'] = true if Docker.version['Version'] >= '1.10.0'
      host_config['VolumesFrom'] = cmd_options[:'volumes-from'] if cmd_options[:'volumes-from'] && !cmd_options[:'volumes-from'].empty?

      add_network_config(options, cmd_options)

      if global_options[:'local-bundle']
        host_config['Binds']
          .push([vendor_dir, "/src/#{project_name}/vendor"].join(':'))
          .push([dot_bundle_dir, "/src/#{project_name}/.bundle"].join(':'))
      end

      container = Docker::Container.create(options.tap { |o| DebugMixin.debug_write "creating container with options #{o.inspect}" })

      begin
        DebugMixin.debug_write "Testing #{project_name} in container #{container.id}\n"

        spawn("docker logs -f #{container.id}", [:out, :err] => $stderr).tap do |pid|
          Process.detach pid
        end
        container.start!

        # Wait for pg/main so that migrations can run
        30.times do
          stdout, stderr, exitcode = container.exec %w(sv status pg/main), &DebugMixin::DOCKER
          status = stdout.join
          break if exitcode == 0 && status =~ /^run\:/
          sleep 1
        end

        # If we're not using shared gems, run dev-install instead of
        # test-install. Even having to reinstall all the gems is
        # better than dealing with Docker For Mac's current file
        # sharing performance.
        install_cmd = global_options[:'local-bundle'] ? 'test-install' : 'dev-install'
        container_command container, "/opt/conjur/evoke/bin/#{install_cmd}", project_name

        DebugMixin.debug_write "Starting conjur\n"

        container_command container, "rm", "/etc/service/conjur/down"
        container_command container, "sv", "start", "conjur"
        wait_for_conjur appliance_image, container

        system "./#{test_script} #{container.id}"
        exit_now! "#{test_script} failed with exit code #{$?.exitstatus}", $?.exitstatus unless $?.exitstatus == 0
      ensure
        unless cmd_options[:keep] || ENV['KEEP_CONTAINERS']
          DebugMixin.debug_write "deleting container"
          container.delete(force: true)
        end
      end
    end
  end
end

desc "Setup a development sandbox for a Conjur debian package in a Conjur appliance container"
long_desc <<DESC
First, a Conjur appliance container is created and started. By default, the
container image is registry.tld/conjur-appliance-cuke-master. An image tag
MUST be supplied. This image is configured with all the CONJUR_ environment
variables setup for the local environment (appliance URL, cert path, admin username and
password, etc). The project source tree is also mounted into the container, at
/src/<project-name>, where <project-name> is taken from the name of the current working directory.

Once in the container, use "/opt/conjur/evoke/bin/dev-install" to install the development bundle of your project.
DESC
command "sandbox" do |c|
  c.desc "Set the current working directory"
  c.flag [:d, :dir]

  c.desc "Image name"
  c.default_value "registry.tld/conjur-appliance-cuke-master"
  c.flag [:i, :image]

  c.desc "Image tag, e.g. 4.5-stable, 4.6-stable"
  c.flag [:t, "image-tag"]

  c.desc "Bind another source directory into the container. Use <src>:<dest>, where both are full paths."
  c.flag [:"bind"], :multiple => true

  c.desc "'docker pull' the Conjur container image"
  c.default_value false
  c.switch [:pull]

  network_options(c)

  c.desc "Specify volume for container"
  c.flag [:'volumes-from'], :multiple => true

  c.desc "Expose a port from the container to host. Use <host>:<container>."
  c.flag [:p, :port], :multiple => true

  c.desc 'Run dev-install in /src/<project-name>'
  c.default_value false
  c.switch [:'dev-install']

  c.desc 'Kill previous sandbox container'
  c.default_value false
  c.switch [:kill]

  c.desc 'A command to run in the sandbox'
  c.flag [:c, :command]

  c.action do |global_options, cmd_options, args|
    raise "Received extra command-line arguments" if args.shift

    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)

    raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)

    Dir.chdir dir do
      image_tag = cmd_options["image-tag"] or raise "image-tag is required"
      appliance_image_id = [cmd_options[:image], image_tag].join(":")

      appliance_image = if cmd_options[:pull]
        begin
          tries ||= 2
          Docker::Image.create 'fromImage' => appliance_image_id, &DebugMixin::DOCKER if cmd_options[:pull]
        rescue
          login_to_registry appliance_image_id
          retry unless (tries -= 1).zero?
        end
      else
        Docker::Image.get appliance_image_id
      end

      project_name = File.basename(Dir.getwd)
      vendor_dir = File.expand_path("tmp/debify/#{project_name}/vendor", ENV['HOME'])
      dot_bundle_dir = File.expand_path("tmp/debify/#{project_name}/.bundle", ENV['HOME'])
      FileUtils.mkdir_p vendor_dir
      FileUtils.mkdir_p dot_bundle_dir

      options = {
        'name' => "#{project_name}-sandbox",
        'Image' => appliance_image.id,
        'WorkingDir' => "/src/#{project_name}",
        'Env' => [
          "CONJUR_AUTHN_LOGIN=admin",
          "CONJUR_ENV=appliance",
          "CONJUR_AUTHN_API_KEY=SEcret12!!!!",
          "CONJUR_ADMIN_PASSWORD=SEcret12!!!!",
        ] + global_options[:env]
      }

      options['HostConfig'] = host_config = {}
      host_config['Binds'] = [
        [File.expand_path(".ssh/id_rsa", ENV['HOME']), "/root/.ssh/id_rsa", 'ro'].join(':'),
        [dir, "/src/#{project_name}"].join(':'),
      ] + Array(cmd_options[:bind])

      if global_options[:'local-bundle']
        host_config['Binds']
          .push([vendor_dir, "/src/#{project_name}/vendor"].join(':'))
          .push([dot_bundle_dir, "/src/#{project_name}/.bundle"].join(':'))
      end

      host_config['Privileged'] = true if Docker.version['Version'] >= '1.10.0'
      host_config['VolumesFrom'] = cmd_options[:'volumes-from'] unless cmd_options[:'volumes-from'].empty?

      add_network_config(options, cmd_options)

      unless cmd_options[:port].empty?
        port_bindings = Hash.new({})
        cmd_options[:port].each do |mapping|
          hport, cport = mapping.split(':')
          port_bindings["#{cport}/tcp"] = [{'HostPort' => hport}]
        end
        host_config['PortBindings'] = port_bindings
      end

      if cmd_options[:kill]
        previous = Docker::Container.get(options['name']) rescue nil
        previous.delete(:force => true) if previous
      end

      container = Docker::Container.create(options.tap { |o| DebugMixin.debug_write "creating container with options #{o.inspect}" })
      $stdout.puts container.id
      container.start!

      wait_for_conjur appliance_image, container

      if cmd_options[:'dev-install']
        container_command(container, "/opt/conjur/evoke/bin/dev-install", project_name)
        container_command(container, 'sv', 'restart', "conjur/#{project_name}")
      end

      if cmd_options[:command]
        container_command(container, '/bin/bash', '-c', cmd_options[:command])
      end
    end
  end
end

desc "Publish a debian package to apt repository"
long_desc <<DESC
Publishes a deb created with `debify package` to our private apt repository.

"distribution" should match the major/minor version of the Conjur appliance you want to install to.

The package name is a required option. The package version can be specified as a CLI option, or it will
be auto-detected from Git.

--component should be 'stable' if run after package tests pass or 'testing' if the package is not yet ready for release.
If you don't specify the component, it will be set to 'testing' unless the current git branch is 'master' or 'origin/master'.
The git branch is first detected from the env var GIT_BRANCH or BRANCH_NAME, and then by checking `git rev-parse --abbrev-ref HEAD`
(which won't give you the answer you want when detached).

DESC
arg_name "distribution project-name"
command "publish" do |c|
  c.desc "Set the current working directory"
  c.flag [:d, :dir]

  c.desc "Specify the deb package version; by default, it's computed automatically"
  c.flag [:v, :version]

  c.desc "Component to publish to, either 'stable' or the name of the git branch"
  c.flag [:c, :component]

  c.desc "Artifactory URL to publish to"
  c.default_value "https://conjurinc.jfrog.io/conjurinc"
  c.flag [:u, :url]

  c.desc "Artifactory Debian repo to publish package to"
  c.default_value "debian-private"
  c.flag [:r, :repo]

  c.desc "Artifactory RPM repo to publish package to"
  c.default_value "redhat-private"
  c.flag ['rpm-repo']

  c.action do |global_options, cmd_options, args|
    require 'conjur/debify/action/publish'
    raise "distribution is required" unless distribution = args.shift
    raise "project-name is required" unless project_name = args.shift
    raise "Received extra command-line arguments" if args.shift

    Conjur::Debify::Action::Publish.new(distribution, project_name, cmd_options).run
  end
end

desc "Auto-detect and print the repository version"
command "detect-version" do |c|
  c.desc "Set the current working directory"
  c.flag [:d, :dir]
  c.action do |global_options, cmd_options, args|
    raise "Received extra command-line arguments" if args.shift

    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)

    raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)

    Dir.chdir dir do
      puts detect_version
    end
  end
end

desc 'Show the given configuration'
arg_name 'configuration'
command 'config' do |c|
  c.action do |_, _, args|
    raise 'no configuration provided' unless config = args.shift
    raise "Received extra command-line arguments" if args.shift

    File.open(File.join('distrib', config)).each do |line|
      puts line.gsub(/@@DEBIFY_VERSION@@/, Conjur::Debify::VERSION)
    end
  end
end


pre do |global, command, options, args|
  # Pre logic here
  # Return true to proceed; false to abort and not call the
  # chosen command
  # Use skips_pre before a command to skip this block
  # on that command only
  true
end

post do |global, command, options, args|
  # Post logic here
  # Use skips_post before a command to skip this
  # block on that command only
end

on_error do |exception|
  # Error logic here
  # return false to skip default error handling
  true
end

