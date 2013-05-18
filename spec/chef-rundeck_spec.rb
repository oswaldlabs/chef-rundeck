require 'spec_helper'

describe 'ChefRundeck' do
  ChefRundeck.config_file = "#{ENV['TRAVIS_BUILD_DIR']}/spec/support/client.rb"
  it 'should return false' do
    get '/' 
    last_response.should be_ok
  end

end
