require 'spec_helper'
require 'nokogiri'

describe 'ChefRundeck' do
  before do
    # setup for the following tests
    ChefRundeck.config_file = "#{ENV['TRAVIS_BUILD_DIR']}/spec/support/client.rb"
    ChefRundeck.username = ENV['USER']
    ChefRundeck.web_ui_url = 'https://manage.opscode.com'
    ChefRundeck.project_config = "#{ENV['TRAVIS_BUILD_DIR']}/spec/support/chef-rundeck.json"
    ChefRundeck.cache_timeout = 0
    ChefRundeck.environment = :development
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
  it 'fetched document should be node1 only' do
    get '/node1_systems'
    last_response.should be_ok
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']").length().should == 1
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']").length().should == 0
  end
  it 'fetched document should be node2 only' do
    get '/node2_systems'
    last_response.should be_ok
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']").length().should == 0
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']").length().should == 1
  end 
  it 'check custom attributes on node2 only' do
    get '/node2_systems'
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute").length().should == 2
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[0].text.should == "linux"
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[1].text.should == "centos"
  end
  it 'check partial search' do
    ChefRundeck.partial_search = true
    get '/node2_systems'
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute").length().should == 2
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[0].text.should == "linux"
    Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[1].text.should == "centos"
  end
end
