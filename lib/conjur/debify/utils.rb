require 'rubygems/package'

module Conjur::Debify::Utils
  module_function

  # copy a file from container to the current working directory
  def copy_from_container container, path
    tar = StringIO.new
    container.copy(path) { |chunk| tar.write chunk }
    tar.rewind
    Gem::Package::TarReader.new(tar).each do |entry|
      File.write entry.full_name, entry.read
    end
  end
end

