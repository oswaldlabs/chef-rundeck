require 'spec_helper'

describe 'ChefRundeck' do
  ChefRundeck.config_file = "#{ENV['TRAVIS_BUILD_DIR']}/spec/support/client.rb"
  ChefRundeck.configure
  it 'should return false' do
    get '/' 
    last_response.should_not be_ok
  end
end
