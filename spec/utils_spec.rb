require 'fakefs/safe'

require 'conjur/debify/utils'

describe 'Conjur::Debify::Utils.copy_from_container' do
  it "copies a file from the container to the current directory" do
    tar = File.read "#{__dir__}/data/test.tar"
    container = instance_double Docker::Container
    allow(container).to receive(:archive_out).with "/tmp/test.tar" do |&b|
      StringIO.new(tar).each(nil, 512) do |c|
        # docker api sends three arguments, so emulate that
        b[c, nil, nil]
      end
    end

    FakeFS do
      Conjur::Debify::Utils.copy_from_container container, "/tmp/test.tar"
      expect(File.read 'test.txt').to eq "this is a test\n"
    end
  end
end

