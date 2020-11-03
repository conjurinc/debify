require 'spec_helper'
require 'conjur/debify/action/publish'

describe Conjur::Debify::Action::Publish do

  let (:cmd_options) {
    {
      :version => '1.0.0',
      :component => 'stable'
    }
  }

  let (:action) { Conjur::Debify::Action::Publish.new('dist', 'proj', cmd_options) }

  before do
    allow(DebugMixin).to receive(:debug_write)
    
    allow(action).to receive(:create_image).and_return(double('publish_image', :id => 'a1b2c3d4'))
  end
  
  context 'with artifactory creds in the environment' do

    before do
      ENV['ARTIFACTORY_USER'] = 'art_user'
      ENV['ARTIFACTORY_PASSWORD'] = 'art_password'
    end

    after do
      ENV.delete('ARTIFACTORY_USER')
      ENV.delete('ARTIFACTORY_PASSWORD')
    end
    
    it 'runs' do
      expect(action).to receive(:publish).twice

      action.run
    end
    
  end

  context 'without artifactory creds in the environment' do

    it 'runs' do
      expect(action).to receive(:fetch_art_creds)
      expect(action).to receive(:publish).twice

      action.run
    end
  end
  
end

    
    
