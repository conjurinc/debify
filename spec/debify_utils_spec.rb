require 'spec_helper'
require 'aruba/rspec'

Aruba.configure do |c|
  c.activate_announcer_on_command_failure = %i(stderr stdout)
end

describe "remove_matching()", type: :aruba do
  it "removes matching files" do
    here %w(foo bar/baz bar/xyzzy zork)
    there %w(foo bar/baz not)
    remove_matching
    expect(contents_of herepath).to match_array %w(zork bar bar/xyzzy)
  end
  
  it "also handles files with spaces in names" do
    here ['foo', 'bar/baz', 'with space', 'with', 'bar/another space']
    there ['with space', 'bar/another space here']
    remove_matching
    expect(contents_of herepath).to match_array ['foo', 'bar', 'bar/baz', 'with', 'bar/another space']
  end
  
  # auxiliary methods and setup
  let(:herepath) { Pathname.new Dir.mktmpdir }
  let(:therepath) { Pathname.new Dir.mktmpdir }
  after { [herepath, therepath].each &FileUtils.method(:remove_entry) }

  def contents_of dir
    Dir.chdir(dir) { Dir['**/*'] }
  end

  def remove_matching
    run_command_and_stop "bash -c 'source #{DEBIFY_UTILS_PATH}; cd #{herepath}; remove_matching #{therepath}'"
  end
  
  def here files
    mkfiles herepath, files
  end
  
  def there files
    mkfiles therepath, files
  end

  def mkfiles dir, files  
    return dir if files.empty?
    files.each do |path|
      fullpath = dir + path
      FileUtils.makedirs fullpath.dirname
      FileUtils.touch fullpath
    end
  end
  
  DEBIFY_UTILS_PATH = File.expand_path '../../lib/conjur/fpm/debify_utils.sh', __FILE__
end

