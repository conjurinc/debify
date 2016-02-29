require "conjur/debify/version"
require 'docker'
require 'fileutils'
require 'gli'

include GLI::App

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
         line = JSON.parse(line)
         line.keys.each do |k|
           debug line[k]
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
  `git describe --long --tags --abbrev=7 --match 'v*.*.*' | sed -e 's/^v//'`.strip.tap do |version|
    raise "No Git version (tag) for project" if version.empty?
  end
end

def git_files
  (`git ls-files -z`.split("\x0") + ['Gemfile.lock']).uniq
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
  c.flag [ :d, "dir" ]
    
  c.desc "Ignore (don't delete) a file or directory"
  c.flag [ :i, :ignore ]
  
  c.desc "Force file deletion even if if this doesn't look like a Jenkins environment"
  c.switch [ :force ]
    
  c.action do |global_options,cmd_options,args|
    def looks_like_jenkins?
      require 'etc'
      Etc.getlogin == 'jenkins' && ENV['BUILD_NUMBER']
    end
    
    require 'set'
    perform_deletion = cmd_options[:force] || looks_like_jenkins?
    if !perform_deletion
      $stderr.puts "No --force, and this doesn't look like Jenkins. I won't actually delete anything"
    end
    @ignore_list = Array(cmd_options[:ignore]) + [ '.', '..', '.git' ]
     
    def ignore_file? f
      @ignore_list.find{|ignore| f.index(ignore) == 0}
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
      delete_files.delete_if{|file| 
        File.directory?(file) || ignore_file?(file)
      }
      if perform_deletion
        image = Docker::Image.create 'fromImage' => "alpine:3.3"
        options = {
          'Cmd'   => [ "sh", "-c", "while true; do sleep 1; done" ],
          'Image' => image.id,
          'Binds' => [
            [ dir, "/src" ].join(':'),
          ]
        }
        container = Docker::Container.create options
        begin
          container.start
          delete_files.each do |file|
            puts file
            
            file = "/src/#{file}"
            cmd = [ "rm", "-f", file ]
            
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
  c.flag [ :d, "dir" ]
  
  c.desc "Specify the deb version; by default, it's computed from the Git tag"
  c.flag [ :v, :version ]

  c.desc "Specify a custom Dockerfile.fpm"
  c.flag [ :dockerfile]
  
  c.action do |global_options,cmd_options,args|
    raise "project-name is required" unless project_name = args.shift
    
    fpm_args = []
    if (delimeter = args.shift) == '--'
      fpm_args = args.dup
    else
      raise "Unexpected argument '#{delimiter}'"
    end
    
    dir = cmd_options[:dir] || '.'
    pwd = File.dirname(__FILE__)

    fpm_image = Docker::Image.build_from_dir File.expand_path('fpm', File.dirname(__FILE__)), tag: "debify-fpm", &DebugMixin::DOCKER
    DebugMixin.debug_write "Built base fpm image '#{fpm_image.id}'\n"
    dir = File.expand_path(dir)
    Dir.chdir dir do
      version = cmd_options[:version] || detect_version
      dockerfile_path = cmd_options[:dockerfile] || File.expand_path("debify/Dockerfile.fpm", pwd)
      dockerfile = File.read(dockerfile_path)

      package_name = "conjur-#{project_name}_#{version}_amd64.deb"
      
      output = StringIO.new
      Gem::Package::TarWriter.new(output) do |tar|
        git_files.each do |fname|
          stat = File.stat(fname)
          tar.add_file(fname, stat.mode) { |tar_file| tar_file.write(File.read(fname)) }
        end
        tar.add_file('Dockerfile', 0640) { |tar_file| tar_file.write dockerfile.gsub("@@image@@", fpm_image.id) }
      end
      output.rewind
        
      image = Docker::Image.build_from_tar output, &DebugMixin::DOCKER

      DebugMixin.debug_write "Built fpm image '#{image.id}' for project #{project_name}\n"

      options = {
        'Cmd'   => [ project_name, version ] + fpm_args,
        'Image' => image.id
      }
      
      container = Docker::Container.create options
      begin
        DebugMixin.debug_write "Packaging #{project_name} in container #{container.id}\n"
        container.tap(&:start).attach { |stream, chunk| $stderr.puts chunk }
        status = container.wait
        raise "Failed to package #{project_name}" unless status['StatusCode'] == 0
        
        require 'rubygems/package'
        deb = StringIO.new
        container.copy("/src/#{package_name}") { |chunk| deb.write(chunk) }
        deb.rewind
        tar = Gem::Package::TarReader.new deb
        tar.first.tap do |entry|
          open(entry.full_name, 'wb') {|f| f.write(entry.read)}
          puts entry.full_name
        end
      ensure
        container.delete(force: true)
      end
    end
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
  c.flag [ :d, :dir ]

  c.desc "Keep the Conjur appliance container after the command finishes"
  c.default_value false
  c.switch [ :k, :keep ]

  c.desc "Image name"
  c.default_value "registry.tld/conjur-appliance-cuke-master"
  c.flag [ :i, :image ]
  
  c.desc "Image tag, e.g. 4.5-stable, 4.6-stable"
  c.flag [ :t, "image-tag"]
  
  c.desc "'docker pull' the Conjur container image"
  c.default_value true
  c.switch [ :pull ]

  c.desc "Specify the deb version; by default, it's computed from the Git tag"
  c.flag [ :v, :version ]
        
  c.action do |global_options,cmd_options,args|
    raise "project-name is required" unless project_name = args.shift
    raise "test-script is required" unless test_script = args.shift
    raise "Receive extra command-line arguments" if args.shift
    
    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)
    
    raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)
    raise "Directory #{dir} does not contain a .deb file" unless Dir["#{dir}/*.deb"].length >= 1
    
    Dir.chdir dir do
      image_tag = cmd_options["image-tag"] or raise "image-tag is required"
      appliance_image_id = [ cmd_options[:image], image_tag ].join(":")
      version = cmd_options[:version] || detect_version
      package_name = "conjur-#{project_name}_#{version}_amd64.deb"
        
      raise "#{test_script} does not exist or is not a file" unless File.file?(test_script)
      
      Docker::Image.create 'fromImage' => appliance_image_id, &DebugMixin::DOCKER if cmd_options[:pull]
      
      def build_test_image(appliance_image_id, project_name, package_name)
        dockerfile = <<-DOCKERFILE
FROM #{appliance_image_id}

COPY #{package_name} /tmp/

RUN if dpkg --list | grep conjur-#{project_name}; then dpkg --force all --purge conjur-#{project_name}; fi
RUN if [ -f /opt/conjur/etc/#{project_name}.conf ]; then rm /opt/conjur/etc/#{project_name}.conf; fi
RUN dpkg --install /tmp/#{package_name}

RUN touch /etc/service/conjur/down
        DOCKERFILE
        Dir.mktmpdir do |tmpdir|
          tmpfile = Tempfile.new('Dockerfile', tmpdir)
          File.write(tmpfile, dockerfile)
          dockerfile_name = File.basename(tmpfile.path)
          tar_cmd = "tar -cvzh -C #{tmpdir} #{dockerfile_name} -C #{Dir.pwd} #{package_name}"
          tar = open("| #{tar_cmd}")
          begin
            Docker::Image.build_from_tar(tar, :dockerfile => dockerfile_name, &DebugMixin::DOCKER)
          ensure
            tar.close
          end
        end
      end

      appliance_image = build_test_image(appliance_image_id, project_name, package_name)
      
      vendor_dir = File.expand_path("tmp/debify/#{project_name}/vendor", ENV['HOME'])
      dot_bundle_dir = File.expand_path("tmp/debify/#{project_name}/.bundle", ENV['HOME'])
      FileUtils.mkdir_p vendor_dir
      FileUtils.mkdir_p dot_bundle_dir
      options = {
        'Image' => appliance_image.id,
        'Env' => [
          "CONJUR_AUTHN_LOGIN=admin",
          "CONJUR_ENV=appliance",
          "CONJUR_AUTHN_API_KEY=secret",
          "CONJUR_ADMIN_PASSWORD=secret",
        ],
        'Binds' => [
          [ dir, "/src/#{project_name}" ].join(':'),
          [ vendor_dir, "/src/#{project_name}/vendor" ].join(':'),
          [ dot_bundle_dir, "/src/#{project_name}/.bundle" ].join(':')
        ]
      }
      
      container = Docker::Container.create(options)
      
      def wait_for_conjur appliance_image, container
        wait_options = {
          'Image' => appliance_image.id,
          'Entrypoint' => '/opt/conjur/evoke/bin/wait_for_conjur',
          'HostConfig' => {
            'Links' => [
              [ container.id, 'conjur' ].join(":")
            ]
          }
        }
  
        wait_container = Docker::Container.create wait_options
        begin
          spawn("docker logs -f #{wait_container.id}", [ :out, :err ] => $stderr).tap do |pid|
            Process.detach pid
          end
          wait_container.start
          status = wait_container.wait
          raise "wait_for_conjur failed" unless status['StatusCode'] == 0
        ensure
          wait_container.delete(force: true)
        end
      end
      
      def command container, *args
        stdout, stderr, exitcode = container.exec args, &DebugMixin::DOCKER
        exit_now! "Command failed : #{args.join(' ')}", exitcode unless exitcode == 0
        stdout
      end
      
      begin
        DebugMixin.debug_write "Testing #{project_name} in container #{container.id}\n"

        spawn("docker logs -f #{container.id}", [ :out, :err ] => $stderr).tap do |pid|
          Process.detach pid
        end
        container.start

        # Wait for pg/main so that migrations can run
        30.times do
          stdout, stderr, exitcode = container.exec %w(sv status pg/main), &DebugMixin::DOCKER
          status = stdout.join
          break if exitcode == 0 && status =~ /^run\:/
          sleep 1
        end
        
        command container, "/opt/conjur/evoke/bin/test-install", project_name

        DebugMixin.debug_write "Starting conjur\n"

        command container, "rm", "/etc/service/conjur/down"
        command container, "sv", "start", "conjur"
        wait_for_conjur appliance_image, container
  
        system "./#{test_script} #{container.id}"
        exit_now! "#{test_script} failed with exit code #{$?.exitstatus}", $?.exitstatus unless $?.exitstatus == 0
      ensure
        container.delete(force: true) unless cmd_options[:keep]
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
The git branch is first detected from the env var GIT_BRANCH, and then by checking `git rev-parse --abbrev-ref HEAD`
(which won't give you the answer you want when detached).

DESC
arg_name "distribution project-name"
command "publish" do |c|
  c.desc "Set the current working directory"
  c.flag [ :d, :dir ]
    
  c.desc "Specify the deb package version; by default, it's computed from the Git tag"
  c.flag [ :v, :version ]

  c.desc "Maturity stage of the package, 'testing' or 'stable'"
  c.flag [ :c, :component ]

  c.action do |global_options,cmd_options,args|
    raise "distribution is required" unless distribution = args.shift
    raise "project-name is required" unless project_name = args.shift
    raise "Receive extra command-line arguments" if args.shift

    def detect_component
      branch = ENV['GIT_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip
      if %w(master origin/master).include?(branch)
        'stable'
      else
        'testing'
      end
    end

    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)
    
    raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)
        
    Dir.chdir dir do
      version = cmd_options[:version] || detect_version
      component = cmd_options[:component] || detect_component
      package_name = "conjur-#{project_name}_#{version}_amd64.deb"

      publish_image = Docker::Image.build_from_dir File.expand_path('publish', File.dirname(__FILE__)), tag: "debify-publish", &DebugMixin::DOCKER
      DebugMixin.debug_write "Built base publish image '#{publish_image.id}'\n"
      
      require 'conjur/cli'
      require 'conjur/authn'
      Conjur::Config.load
      Conjur::Config.apply
      conjur = Conjur::Authn.connect nil, noask: true
      
      art_username = conjur.variable('artifactory/users/jenkins/username').value
      art_password = conjur.variable('artifactory/users/jenkins/password').value

      options = {
          'Image' => publish_image.id,
          'Cmd' => [
              "art", "upload",
              "--url", "https://conjurinc.artifactoryonline.com/conjurinc",
              "--user", art_username,
              "--password", art_password,
              "--deb", "#{distribution}/#{component}/amd64",
              package_name, "debian-local/"
          ],
          'Binds' => [
              [ dir, "/src" ].join(':')
          ]
      }
  
      container = Docker::Container.create(options)
      begin
        container.tap(&:start).streaming_logs(follow: true, stdout: true, stderr: true) { |stream, chunk| puts "#{chunk}" }
        status = container.wait
        raise "Failed to publish #{package_name}" unless status['StatusCode'] == 0
      ensure
        container.delete(force: true)
      end
    end
  end
end
  
pre do |global,command,options,args|
  # Pre logic here
  # Return true to proceed; false to abort and not call the
  # chosen command
  # Use skips_pre before a command to skip this block
  # on that command only
  true
end

post do |global,command,options,args|
  # Post logic here
  # Use skips_post before a command to skip this
  # block on that command only
end

on_error do |exception|
  # Error logic here
  # return false to skip default error handling
  true
end

