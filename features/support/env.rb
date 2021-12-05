require 'aruba/cucumber'
require 'docker-api'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Aruba.configure do |config|
  config.exit_timeout = 1200
  # not a best practice from aruba's point of view
  # but the only solution I've found to have docker credentials context
  config.home_directory = ENV['HOME']
end
