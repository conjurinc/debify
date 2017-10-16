require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'

def cucumber?
  require 'cucumber'
  require 'cucumber/rake/task'
rescue LoadError
  false
end

def rspec?
  require 'rspec/core/rake_task'
  require 'ci/reporter/rake/rspec'
end
  
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

spec = eval(File.read('debify.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

if cucumber?
  CUKE_RESULTS = 'features/reports'

  desc 'Run features'
  Cucumber::Rake::Task.new(:features) do |t|
    opts = "features --format junit -o #{CUKE_RESULTS} --format pretty -x"
    opts += " --tags #{ENV['TAGS']}" if ENV['TAGS']
    t.cucumber_opts =  opts
    t.fork = false
  end

  desc 'Run features tagged as work-in-progress (@wip)'
  Cucumber::Rake::Task.new('features:wip') do |t|
    tag_opts = ' --tags ~@pending'
    tag_opts = ' --tags @wip'
    t.cucumber_opts = "features --format junit -o #{CUKE_RESULTS} --format pretty -x -s#{tag_opts}"
    t.fork = false
  end

  task :cucumber => :features
  task 'cucumber:wip' => 'features:wip'
  task :wip => 'features:wip'
end

if rspec?
  desc 'Run specs'
  RSpec::Core::RakeTask.new(:spec)
  task :spec => 'ci:setup:rspec'
end
