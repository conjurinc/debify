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
    a.each do |line|
      line = JSON.parse(line)
      line.keys.each do |k|
        debug line[k]
      end
    end
  end

  DOCKER = method :docker_debug
end

program_desc 'Describe your application here'

version Debify::VERSION

subcommand_option_handling :normal
arguments :strict

desc 'Describe some switch here'
switch [:s,:switch]

desc 'Describe some flag here'
default_value 'the default'
arg_name 'The name of the argument'
flag [:f,:flagname]

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
arg_name "project_name -- <fpm-arguments>"
command "package" do |c|
  c.desc "Set the current working directory"
  c.flag [ :d, "dir" ]
  
  c.desc "Specify the deb version; by default, it's computed from the Git tag"
  c.flag [ :v, :version ]
  
  c.action do |global_options,options,args|
    raise "project_name is required" unless project_name = args.shift
    fpm_args = []
    if (delimeter = args.shift) == '--'
      fpm_args = args.dup
    else
      raise "Unexpected argument '#{delimiter}'"
    end
    
    dir = options[:dir] || '.'
    pwd = File.dirname(__FILE__)
    version = options[:version]

    fpm_image = Docker::Image.build_from_dir File.expand_path('fpm', File.dirname(__FILE__)), tag: "debify-fpm", &DebugMixin::DOCKER
    DebugMixin.debug_write "Built base fpm image '#{fpm_image.id}'\n"
    dir = File.expand_path(dir)
    Dir.chdir dir do
      unless version
        version = `git describe --long --tags --abbrev=7 | sed -e 's/^v//'`.strip
        raise "No Git version (tag) for project '#{project_name}'" if version.empty?
      end

      package_name = "conjur-#{project_name}_#{version}_amd64.deb"
      system "docker pull conjurinc/fpm 1>&2"
      
      output = StringIO.new
      Gem::Package::TarWriter.new(output) do |tar|
        `find . -type f`.split("\n").each do |fname|
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
        spawn("docker logs -f #{container.id}", [ :out, :err ] => $stderr).tap do |pid|
          Process.detach pid
        end
        container.start
        container.wait
        
        deb_file = nil
        Dir.chdir(tempdir) do
          deb_file = Dir["*.deb"]
          raise "Expected one deb file, got #{deb_file.join(', ')}" unless deb_file.length == 1
          deb_file = deb_file[0]
          FileUtils.cp deb_file, dir
        end
        puts File.basename(deb_file)
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
