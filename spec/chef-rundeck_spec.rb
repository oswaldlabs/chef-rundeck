require 'spec_helper'
require 'nokogiri'

describe 'ChefRundeck' do
  before do
    # setup for the following tests
    ChefRundeck.config_file = "#{ENV['TRAVIS_BUILD_DIR']}/spec/support/client.rb"
    ChefRundeck.username = ENV['USER']
    ChefRundeck.web_ui_url = 'https://manage.opscode.com'
    ChefRundeck.configure
  end
  it 'fetch to root should return 200' do
    get '/' 
    last_response.should be_ok
  end
  it 'fetched document should be Nokogiri-parseable XML document' do
    get '/'
    Nokogiri::XML(last_response.body).document.should be_true
  end
end
