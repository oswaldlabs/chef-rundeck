require 'spec_helper'

describe 'ChefRundeck' do
  it 'should return false' do
    ChefRundeck.config_file = "#{ENV['TRAVIS_BUILD_DIR']}/spec/support/client.rb"
    ChefRundeck.username = ENV['USER']
    ChefRundeck.web_ui_url = 'https://manage.opscode.com'
    ChefRundeck.configure

    get '/' 
    last_response.should be_ok
  end

end
