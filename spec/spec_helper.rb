$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'chef-rundeck'
require 'sinatra'
require 'rspec'
require 'rack/test'


set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

  def app
    ChefRundeck.new
  end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
