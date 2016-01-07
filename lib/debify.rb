require "debify/version"
require 'docker'
require 'fileutils'

include GLI::App

# This is used to turn on DEBUG notices for the test case operation. For instance,
# messages from "evoke configure"
module DebugMixin
  DEBUG = ENV['DEBUG']

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

program_desc 'Describe your application here'

version Debify::VERSION

subcommand_option_handling :normal
arguments :strict

long_desc <<DESC
Build a debian package for a project.

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
    version = cmd_options[:version]

    fpm_image = Docker::Image.build_from_dir File.expand_path('fpm', File.dirname(__FILE__)), tag: "debify-fpm", &DebugMixin::DOCKER
    DebugMixin.debug_write "Built base fpm image '#{fpm_image.id}'\n"
    dir = File.expand_path(dir)
    Dir.chdir dir do
      unless version
        version = `git describe --long --tags --abbrev=7 | sed -e 's/^v//'`.strip
        raise "No Git version (tag) for project '#{project_name}'" if version.empty?
      end

      package_name = "conjur-#{project_name}_#{version}_amd64.deb"
      
      output = StringIO.new
      Gem::Package::TarWriter.new(output) do |tar|
        `git ls-files -z`.split("\x0").each do |fname|
          stat = File.stat(fname)
          tar.add_file(fname, stat.mode) { |tar_file| tar_file.write(File.read(fname)) }
        end
        tar.add_file('Dockerfile', 0640) { |tar_file| tar_file.write File.read(File.expand_path("debify/Dockerfile.fpm", pwd)).gsub("@@image@@", fpm_image.id) }
      end
      output.rewind
        
      image = Docker::Image.build_from_tar output, &DebugMixin::DOCKER

      DebugMixin.debug_write "Built fpm image '#{image.id}' for project #{project_name}\n"

      # Make it under HOME so that Docker can map the volume on MacOS
      tempdir = File.expand_path((0...50).map { ('a'..'z').to_a[rand(26)] }.join, ENV['HOME'])
      FileUtils.mkdir tempdir
      at_exit do
        FileUtils.rm_rf tempdir
      end
      
      options = {
        'Cmd'   => [ project_name, version ] + fpm_args,
        'Image' => image.id,
        'Binds' => [
          [ tempdir, '/dist' ].join(':')
        ]
      }
      
      container = Docker::Container.create options
      begin
        DebugMixin.debug_write "Packaging #{project_name} in container #{container.id}\n"
        container.tap(&:start).attach { |stream, chunk| $stderr.puts chunk }
        status = container.wait
        raise "Failed to package #{project_name}" unless status['StatusCode'] == 0
        
        deb_file = nil
        Dir.chdir(tempdir) do
          deb_file = Dir["*.deb"]
          raise "Expected one deb file, got #{deb_file.join(', ')}" unless deb_file.length == 1
          deb_file = deb_file[0]
          FileUtils.cp deb_file, dir
        end
        FileUtils.ln_sf deb_file, deb_file.gsub(version, "latest")
        puts File.basename(deb_file)
      ensure
        container.delete(force: true)
      end
    end
  end
end

long_desc <<DESC
Test a Conjur debian package in a Conjur appliance container.

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
  
  c.desc "Pull the image, even if it's in the Docker engine already"
  c.default_value true
  c.switch [ :pull ]
    
  c.desc "Shell script to configure the appliance before testing"
  c.flag [ :c, "configure-script" ]
    
  c.action do |global_options,cmd_options,args|
    raise "project-name is required" unless project_name = args.shift
    raise "test-script is required" unless test_script = args.shift
    
    dir = cmd_options[:dir] || '.'
    dir = File.expand_path(dir)
    
    raise "Directory #{dir} does not exist or is not a directory" unless File.directory?(dir)
    raise "Directory #{dir} does not contain a .deb file" unless Dir["#{dir}/*.deb"].length >= 1
    
    Dir.chdir dir do
      image_tag = cmd_options["image-tag"] or raise "image-tag is required"
      appliance_image_id = [ cmd_options[:image], image_tag ].join(":")
      configure_script = cmd_options["configure-script"]
        
      raise "#{configure_script} does not exist or is not a file" unless configure_script.nil? || File.file?(configure_script)
      raise "#{test_script} does not exist or is not a file" unless File.file?(test_script)
        
      appliance_image = if cmd_options[:pull]
        Docker::Image.create 'fromImage' => appliance_image_id, &DebugMixin::DOCKER
      else
        Docker::Image.get(appliance_image_id)
      end
      
      options = {
        'Image' => appliance_image.id,
        'Env' => [
          "CONJUR_APPLIANCE_URL=https://localhost/api",
          "CONJUR_ACCOUNT=cucumber",
          "CONJUR_CERT_FILE=/opt/conjur/etc/ssl/ca.pem",
          "CONJUR_AUTHN_LOGIN=admin",
          "CONJUR_ENV=production",
          "CONJUR_AUTHN_API_KEY=secret",
          "CONJUR_ADMIN_PASSWORD=secret",
        ],
        'Binds' => [
          [ dir, "/src/#{project_name}" ].join(':')
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
      
      begin
        DebugMixin.debug_write "Testing #{project_name} in container #{container.id}\n"
        spawn("docker logs -f #{container.id}", [ :out, :err ] => $stderr).tap do |pid|
          Process.detach pid
        end
        container.start
        
        DebugMixin.debug_write "Waiting for Conjur\n"
        wait_for_conjur appliance_image, container
        
        DebugMixin.debug_write "Installing #{project_name}\n"
        
        stdout, stderr, exitcode = container.exec [ "dpkg", "-i", "/src/#{project_name}/conjur-#{project_name}_latest_amd64.deb" ], &DebugMixin::DOCKER
        exit_now! "deb install failed", exitcode unless exitcode == 0
        stdout, stderr, exitcode = container.exec [ "/opt/conjur/evoke/bin/test-install", project_name ], &DebugMixin::DOCKER
        exit_now! "test-install failed", exitcode unless exitcode == 0
  
        wait_for_conjur appliance_image, container
  
        if configure_script
          system "./#{configure_script} #{container.id}"
          exit_now! "#{configure_script} failed with exit code #{$?.exitstatus}", $?.exitstatus unless $?.exitstatus == 0
          wait_for_conjur appliance_image, container
        end
  
        system "./#{test_script} #{container.id}"
        exit_now! "#{test_script} failed with exit code #{$?.exitstatus}", $?.exitstatus unless $?.exitstatus == 0
      ensure
        container.delete(force: true) unless cmd_options[:keep]
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
