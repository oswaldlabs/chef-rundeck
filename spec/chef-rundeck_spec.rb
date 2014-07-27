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
    expect(last_response).to be_ok
  end
  it 'fetched document should be parseable by Nokogiri without errors' do
    get '/'
    expect(Nokogiri::XML(last_response.body).document.errors).to be_empty
  end
  it 'data for node1 should contain tag attribute with Chef node object\'s tag, role, recipes in run list and environment' do
    get '/'
    expect(last_response).to be_ok
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']/@tags").text()).to include("role1")
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']/@tags").text()).to include("cookbook::default")
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']/@tags").text()).to include("tag1")
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']/@tags").text()).to include("development")
  end
  it 'fetched document for first test project should be node1 only' do
    get '/node1_systems'
    expect(last_response).to be_ok
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']").length()).to eq(1)
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']").length()).to eq(0)
  end
  it 'fetched document should be node1 only verify hostname override' do
    get '/node1_systems'
    expect(last_response).to be_ok
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']/@hostname").text()).to eq("10.0.0.1")
  end
  it 'fetched document should be node2 only verify hostname' do
    get '/node2_systems'
    expect(last_response).to be_ok
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/@hostname").text()).to eq("node2.chefrundeck.local")
  end
  it 'fetched document should be node2 only' do
    get '/node2_systems'
    expect(last_response).to be_ok
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']").length()).to eq(0)
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']").length()).to eq(1)
  end 
  it 'check custom attributes on node2 only' do
    get '/node2_systems'
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute").length()).to eq(2)
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[0].text).to eq("linux")
    expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[1].text).to eq("centos")
  end
  context 'when partial search is enabled' do
    before do
      ChefRundeck.partial_search = true
    end
    it 'check partial search' do
      get '/node2_systems'
      expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute").length()).to eq(2)
      expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[0].text).to eq("linux")
      expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/attribute")[1].text).to eq("centos")
    end
    it 'fetched document should be node1 only verify hostname override' do
      get '/node1_systems'
    expect(last_response).to be_ok
      expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node1.chefrundeck.local']/@hostname").text).to eq("10.0.0.1")
    end
    it 'fetched document should be node2 only verify hostname' do
      get '/node2_systems'
    expect(last_response).to be_ok
      expect(Nokogiri::XML(last_response.body).xpath("//project/node[@name='node2.chefrundeck.local']/@hostname").text).to eq("node2.chefrundeck.local")
    end
  end
end
